import TonSwift

public struct TransferData {
    public let sender: Address
    public let sendMode: SendMode
    public let internalMessages: [MessageRelaxed]
}
