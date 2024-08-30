import Combine
import HsExtensions
import HsToolKit
import TonSwift

class EventManager {
    private static let limit = 10

    private let address: Address
    private let api: IApi
    private let storage: EventStorage
    private let logger: Logger?
    private var tasks = Set<AnyTask>()

    @DistinctPublished private(set) var syncState: SyncState = .notSynced(error: Kit.SyncError.notStarted)

    init(address: Address, api: IApi, storage: EventStorage, logger: Logger?) {
        self.address = address
        self.api = api
        self.storage = storage
        self.logger = logger
    }
}

extension EventManager {
    func events(tagQueries: [TagQuery], beforeLt: Int64?, limit: Int?) -> [Event] {
        do {
            return try storage.events(tagQueries: tagQueries, beforeLt: beforeLt, limit: limit ?? 100)
        } catch {
            return []
        }
    }

    func eventPublisher(tagQueries _: [TagQuery]) -> AnyPublisher<[Event], Never> {
        fatalError()
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
                        
                        try? self?.storage.save(events: events)

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
                        
                        try? self?.storage.save(events: events)

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
