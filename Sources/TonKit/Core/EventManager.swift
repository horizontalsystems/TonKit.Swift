import Combine
import HsExtensions
import HsToolKit
import TonSwift

class EventManager {
    private static let limit = 100

    private let address: Address
    private let api: IApi
    private let storage: EventStorage
    private let logger: Logger?
    private var tasks = Set<AnyTask>()

    @DistinctPublished private(set) var syncState: SyncState = .notSynced(error: Kit.SyncError.notStarted)

    private let eventWithTagsSubject = PassthroughSubject<[EventWithTags], Never>()

    init(address: Address, api: IApi, storage: EventStorage, logger: Logger?) {
        self.address = address
        self.api = api
        self.storage = storage
        self.logger = logger
    }

    private func handleLatest(events: [Event]) {
        let inProgressEvents = events.filter { $0.inProgress }
        let completedEvents = events.filter { !$0.inProgress }

        var eventsToHandle = [Event]()

        if !completedEvents.isEmpty {
            let existingEvents = (try? storage.events(ids: completedEvents.map { $0.id })) ?? []

            for completedEvent in completedEvents {
                if let existingEvent = existingEvents.first(where: { $0.id == completedEvent.id }) {
                    if existingEvent.inProgress {
                        eventsToHandle.append(completedEvent)
                    }
                } else {
                    eventsToHandle.append(completedEvent)
                }
            }
        }

        handle(events: inProgressEvents + eventsToHandle)
    }

    private func handle(events: [Event]) {
        guard !events.isEmpty else {
            return
        }

        try? storage.save(events: events)

        let eventsWithTags = events.map { event in
            EventWithTags(event: event, tags: event.tags(address: address))
        }

        let tags = eventsWithTags.map { $0.tags }.flatMap { $0 }
        try? storage.resave(tags: tags, eventIds: events.map { $0.id })

        eventWithTagsSubject.send(eventsWithTags)
    }
}

extension EventManager {
    func events(tagQuery: TagQuery, beforeLt: Int64?, limit: Int?) -> [Event] {
        do {
            return try storage.events(tagQuery: tagQuery, beforeLt: beforeLt, limit: limit ?? 100)
        } catch {
            return []
        }
    }

    func eventPublisher(tagQuery: TagQuery) -> AnyPublisher<[Event], Never> {
        if tagQuery.isEmpty {
            return eventWithTagsSubject
                .map { eventsWithTags in
                    eventsWithTags.map { $0.event }
                }
                .eraseToAnyPublisher()
        } else {
            return eventWithTagsSubject
                .map { eventsWithTags in
                    eventsWithTags.compactMap { eventWithTags -> Event? in
                        for tag in eventWithTags.tags {
                            if tag.conforms(tagQuery: tagQuery) {
                                return eventWithTags.event
                            }
                        }

                        return nil
                    }
                }
                .filter { events in
                    !events.isEmpty
                }
                .eraseToAnyPublisher()
        }
    }

    func tagTokens() -> [TagToken] {
        do {
            return try storage.tagTokens()
        } catch {
            return []
        }
    }

    func sync() {
        logger?.log(level: .debug, message: "Syncing transactions...")

        guard !syncState.syncing else {
            logger?.log(level: .debug, message: "Already syncing transactions")
            return
        }

        syncState = .syncing

        Task { [weak self, address, api, storage] in
            do {
                let latestEvent = try storage.latestEvent()

                if let latestEvent {
                    self?.logger?.log(level: .debug, message: "Fetching latest events...")

                    let startTimestamp = latestEvent.timestamp
                    var beforeLt: Int64?

                    repeat {
                        let events = try await api.getEvents(address: address, beforeLt: beforeLt, startTimestamp: startTimestamp, limit: Self.limit)
                        self?.logger?.log(level: .debug, message: "Got latest events: \(events.count), beforeLt: \(beforeLt ?? -1), startTimestamp: \(startTimestamp)")

                        self?.handleLatest(events: events)

                        if events.count < Self.limit {
                            break
                        }

                        beforeLt = events.last?.lt
                    } while true
                }

                let eventSyncState = try storage.eventSyncState()
                let allSynced = eventSyncState?.allSynced ?? false

                if !allSynced {
                    self?.logger?.log(level: .debug, message: "Fetching history events...")

                    let oldestEvent = try storage.oldestEvent()
                    var beforeLt = oldestEvent?.lt

                    repeat {
                        let events = try await api.getEvents(address: address, beforeLt: beforeLt, startTimestamp: nil, limit: Self.limit)
                        self?.logger?.log(level: .debug, message: "Got history events: \(events.count), beforeLt: \(beforeLt ?? -1)")

                        self?.handle(events: events)

                        if events.count < Self.limit {
                            break
                        }

                        beforeLt = events.last?.lt
                    } while true

                    let newOldestEvent = try storage.oldestEvent()

                    if newOldestEvent != nil {
                        try? storage.save(eventSyncState: .init(allSynced: true))
                    }
                }

                self?.syncState = .synced
            } catch {
                self?.logger?.log(level: .error, message: "Transactions sync error: \(error)")
                self?.syncState = .notSynced(error: error)
            }
        }.store(in: &tasks)
    }
}

extension EventManager {
    private struct EventWithTags {
        let event: Event
        let tags: [Tag]
    }
}
