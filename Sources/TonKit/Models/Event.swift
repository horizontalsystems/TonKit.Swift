import GRDB
import TonSwift

public struct Event: Codable {
    public let id: String
    public let lt: Int64
    public let timestamp: Int64
    public let isScam: Bool
    public let inProgress: Bool
    public let actions: [Action]

    func tags(address: Address) -> [Tag] {
        var tags = [Tag]()

        for action in actions {
            switch action.type {
            case let .tonTransfer(action):
                if action.sender.address == address {
                    tags.append(Tag(eventId: id, type: .outgoing, platform: .native, addresses: [action.recipient.address]))
                }

                if action.recipient.address == address {
                    tags.append(Tag(eventId: id, type: .incoming, platform: .native, addresses: [action.sender.address]))
                }
            case let .jettonTransfer(action):
                if let sender = action.sender, sender.address == address {
                    tags.append(Tag(eventId: id, type: .outgoing, platform: .jetton, jettonAddress: action.jetton.address, addresses: action.recipient.map { [$0.address] } ?? []))
                }

                if let recipient = action.recipient, recipient.address == address {
                    tags.append(Tag(eventId: id, type: .incoming, platform: .jetton, jettonAddress: action.jetton.address, addresses: action.sender.map { [$0.address] } ?? []))
                }
            case let .smartContract(action):
                tags.append(Tag(eventId: id, type: .outgoing, platform: .native, addresses: [action.contract.address]))
            default: ()
            }
        }

        return tags
    }
}

extension Event: FetchableRecord, PersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let lt = Column(CodingKeys.lt)
        static let timestamp = Column(CodingKeys.timestamp)
        static let isScam = Column(CodingKeys.isScam)
        static let isProgress = Column(CodingKeys.inProgress)
        static let actions = Column(CodingKeys.actions)
    }
}

struct EventSyncState: Codable {
    let id: String
    let allSynced: Bool

    init(allSynced: Bool) {
        id = "unique_id"
        self.allSynced = allSynced
    }
}

extension EventSyncState: FetchableRecord, PersistableRecord {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let allSynced = Column(CodingKeys.allSynced)
    }
}
