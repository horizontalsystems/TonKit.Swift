import GRDB
import TonSwift

public class Tag {
    public let type: `Type`
    public let platform: Platform?
    public let jettonAddress: Address?
    public let addresses: [Address]

    public init(type: `Type`, platform: Platform? = nil, jettonAddress: Address? = nil, addresses: [Address] = []) {
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

        if let contractAddress = tagQuery.jettonAddress, contractAddress != jettonAddress {
            return false
        }

        if let address = tagQuery.address, !addresses.contains(address) {
            return false
        }

        return true
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
    }
}
