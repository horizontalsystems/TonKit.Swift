import GRDB

public struct Event: Codable {
    public let id: String
    public let lt: Int64
    public let timestamp: Int64
    public let isScam: Bool
    public let inProgress: Bool
    public let actions: [Action]
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
