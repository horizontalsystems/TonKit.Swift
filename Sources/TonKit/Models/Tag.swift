import GRDB
import TonSwift

public class Tag: Codable {
    public let eventId: String
    public let type: `Type`?
    public let platform: Platform?
    public let jettonAddress: Address?
    public let addresses: [Address]

    public init(eventId: String, type: Type? = nil, platform: Platform? = nil, jettonAddress: Address? = nil, addresses: [Address] = []) {
        self.eventId = eventId
        self.type = type
        self.platform = platform
        self.jettonAddress = jettonAddress
        self.addresses = addresses
    }

    public func conforms(tagQuery: TagQuery) -> Bool {
        if let type = tagQuery.type, self.type != type {
            return false
        }

        if let platform = tagQuery.platform, self.platform != platform {
            return false
        }

        if let jettonAddress = tagQuery.jettonAddress, self.jettonAddress != jettonAddress {
            return false
        }

        if let address = tagQuery.address, !addresses.contains(address) {
            return false
        }

        return true
    }
}

extension Tag: FetchableRecord, PersistableRecord {
    enum Columns {
        static let eventId = Column(CodingKeys.eventId)
        static let type = Column(CodingKeys.type)
        static let platform = Column(CodingKeys.platform)
        static let jettonAddress = Column(CodingKeys.jettonAddress)
        static let addresses = Column(CodingKeys.addresses)
    }
}

public extension Tag {
    enum Platform: String, Codable {
        case native
        case jetton
    }

    enum `Type`: String, Codable {
        case incoming
        case outgoing
        case swap
        case unsupported
    }
}
