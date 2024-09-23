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

    private let eventSubject = PassthroughSubject<EventInfoWithTags, Never>()

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

        handle(events: inProgressEvents + eventsToHandle, initial: false)
    }

    private func handle(events: [Event], initial: Bool) {
        guard !events.isEmpty else {
            return
        }

        try? storage.save(events: events)

        let eventsWithTags = events.map { event in
            EventWithTags(event: event, tags: event.tags(address: address))
        }

        let tags = eventsWithTags.map { $0.tags }.flatMap { $0 }
        try? storage.resave(tags: tags, eventIds: events.map { $0.id })

        eventSubject.send(EventInfoWithTags(events: eventsWithTags, initial: initial))
    }
}

extension EventManager {
    func event(id: String) -> Event? {
        do {
            return try storage.event(id: id)
        } catch {
            return nil
        }
    }

    func events(tagQuery: TagQuery, beforeLt: Int64?, limit: Int?) -> [Event] {
        do {
            return try storage.events(tagQuery: tagQuery, beforeLt: beforeLt, limit: limit ?? 100)
        } catch {
            return []
        }
    }

    func eventPublisher(tagQuery: TagQuery) -> AnyPublisher<EventInfo, Never> {
        if tagQuery.isEmpty {
            return eventSubject
                .map { info in
                    EventInfo(
                        events: info.events.map { $0.event },
                        initial: info.initial
                    )
                }
                .eraseToAnyPublisher()
        } else {
            return eventSubject
                .map { info in
                    EventInfo(
                        events: info.events.compactMap { eventWithTags -> Event? in
                            for tag in eventWithTags.tags {
                                if tag.conforms(tagQuery: tagQuery) {
                                    return eventWithTags.event
                                }
                            }

                            return nil
                        },
                        initial: info.initial
                    )
                }
                .filter { info in
                    !info.events.isEmpty
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

                        self?.handle(events: events, initial: true)

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

    private struct EventInfoWithTags {
        let events: [EventWithTags]
        let initial: Bool
    }
}
