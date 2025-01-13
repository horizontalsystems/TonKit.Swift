import BigInt
import Foundation
import GRDB
import TonSwift

public struct Account: Codable, Equatable {
    public let address: Address
    public let balance: BigUInt
    public let status: Status
}

extension Account: FetchableRecord, PersistableRecord {
    enum Columns {
        static let address = Column(CodingKeys.address)
        static let balance = Column(CodingKeys.balance)
        static let status = Column(CodingKeys.status)
    }
}

public extension Account {
    enum Status: String, Codable {
        case nonexist
        case uninit
        case active
        case frozen
        case unknown

        var stateInitRequired: Bool {
            switch self {
            case .uninit: return true
            default: return false
            }
        }
    }
}
