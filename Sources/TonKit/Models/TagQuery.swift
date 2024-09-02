import TonSwift

public class TagQuery {
    public let type: Tag.`Type`?
    public let platform: Tag.Platform?
    public let jettonAddress: Address?
    public let address: Address?

    public init(type: Tag.`Type`? = nil, platform: Tag.Platform? = nil, jettonAddress: Address? = nil, address: Address? = nil) {
        self.type = type
        self.platform = platform
        self.jettonAddress = jettonAddress
        self.address = address
    }

    var isEmpty: Bool {
        type == nil && platform == nil && jettonAddress == nil && address == nil
    }
}
