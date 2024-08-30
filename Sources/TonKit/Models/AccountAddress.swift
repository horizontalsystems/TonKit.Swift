import TonSwift

public struct AccountAddress: Codable {
    public var address: Address
    public var name: String?
    public var isScam: Bool
    public var isWallet: Bool
}
