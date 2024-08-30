import BigInt
import TonSwift

public struct Action: Codable {
    public let type: Type
    public let status: Status
}

public extension Action {
    enum `Type`: Codable {
        case tonTransfer(action: TonTransfer)
        case jettonTransfer(action: JettonTransfer)
        case smartContract(action: SmartContract)
        case unknown(rawType: String)
    }

    enum Status: String, Codable {
        case ok
        case failed
        case unknown
    }
}

public extension Action {
    struct TonTransfer: Codable {
        public let sender: AccountAddress
        public let recipient: AccountAddress
        public let amount: BigUInt
        public let comment: String?
    }

    struct JettonTransfer: Codable {
        public let sender: AccountAddress?
        public let recipient: AccountAddress?
        public let sendersWallet: Address
        public let recipientsWallet: Address
        public let amount: BigUInt
        public let comment: String?
        public let jetton: Jetton
    }

    struct SmartContract: Codable {
        public let contract: AccountAddress
        public let tonAttached: BigUInt
        public let operation: String
        public let payload: String?
    }
}
