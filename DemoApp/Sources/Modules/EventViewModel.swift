import Combine
import Foundation
import TonKit
import TonSwift

class EventViewModel: ObservableObject {
    private let tonKit: Kit
    private var cancellables = Set<AnyCancellable>()

    @Published var syncState: SyncState
    @Published var events: [Event] = []

    @Published var eventType: EventType = .all {
        didSet {
            syncTagQuery()
        }
    }

    @Published var eventToken: EventToken = .all {
        didSet {
            syncTagQuery()
        }
    }

    @Published var eventAddress: String = "" {
        didSet {
            syncTagQuery()
        }
    }

    init(tonKit: Kit) {
        self.tonKit = tonKit

        syncState = tonKit.syncState

        syncTagQuery()
    }

    private func syncTagQuery() {
        let tagQuery = TagQuery(
            type: eventType.tagType,
            platform: eventToken.tagPlatform,
            jettonAddress: eventToken.tagJettonAddress,
            address: try? Address.parse(eventAddress)
        )

        sync(tagQuery: tagQuery)
        subscribe(tagQuery: tagQuery)
    }

    private func sync(tagQuery: TagQuery) {
        events = tonKit.events(tagQuery: tagQuery)
    }

    private func subscribe(tagQuery: TagQuery) {
        tonKit.eventPublisher(tagQuery: tagQuery)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] events in
                print("Receive: \(events.count)")
                self?.sync(tagQuery: tagQuery)
            }
            .store(in: &cancellables)
    }

    var eventTokens: [EventToken] {
        let jettons: [EventToken] = tonKit.jettonBalanceMap.values.map { jettonBalance in
            .jetton(jetton: jettonBalance.jetton)
        }

        return [.all, .native] + jettons
    }
}

extension EventViewModel {
    enum EventType: String, CaseIterable {
        case all
        case incoming
        case outgoing

        var tagType: Tag.`Type`? {
            switch self {
            case .all: return nil
            case .incoming: return .incoming
            case .outgoing: return .outgoing
            }
        }
    }

    enum EventToken: Hashable {
        case all
        case native
        case jetton(jetton: Jetton)

        var title: String {
            switch self {
            case .all: return "All"
            case .native: return "TON"
            case let .jetton(jetton): return jetton.symbol
            }
        }

        var tagPlatform: Tag.Platform? {
            switch self {
            case .all: return nil
            case .native: return .native
            case .jetton: return .jetton
            }
        }

        var tagJettonAddress: Address? {
            switch self {
            case .all, .native: return nil
            case let .jetton(jetton): return jetton.address
            }
        }
    }
}
