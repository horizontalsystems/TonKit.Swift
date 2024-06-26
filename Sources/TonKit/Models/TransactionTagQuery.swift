import TonSwift

public class TransactionTagQuery {
    public let type: TransactionTag.TagType?
    public let `protocol`: TransactionTag.TagProtocol?
    public let jettonAddress: Address?
    public let address: String?

    public init(type: TransactionTag.TagType? = nil, protocol: TransactionTag.TagProtocol? = nil, jettonAddress: Address? = nil, address: String?) {
        self.type = type
        self.protocol = `protocol`
        self.jettonAddress = jettonAddress
        self.address = address
    }

    var isEmpty: Bool {
        type == nil && `protocol` == nil && jettonAddress == nil && address == nil
    }
}
