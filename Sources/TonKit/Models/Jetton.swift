import Foundation
import TonSwift

public struct Jetton: Codable, Equatable, Hashable {
    public let address: Address
    public let name: String
    public let symbol: String
    public let decimals: Int
    public let image: String?
    public let verification: VerificationType
}

public extension Jetton {
    enum VerificationType: String, Codable {
        case whitelist
        case blacklist
        case none
        case unknown
    }
}
