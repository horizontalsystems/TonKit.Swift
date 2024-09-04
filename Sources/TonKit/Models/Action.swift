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
        case jettonBurn(action: JettonBurn)
        case jettonMint(action: JettonMint)
        case contractDeploy(action: ContractDeploy)
        case jettonSwap(action: JettonSwap)
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

    struct JettonBurn: Codable {
        public let sender: AccountAddress
        public let sendersWallet: Address
        public let amount: BigUInt
        public let jetton: Jetton
    }

    struct JettonMint: Codable {
        public let recipient: AccountAddress
        public let recipientsWallet: Address
        public let amount: BigUInt
        public let jetton: Jetton
    }

    struct ContractDeploy: Codable {
        public let address: Address
        public let interfaces: [String]
    }

    struct JettonSwap: Codable {
        public let dex: String
        public let amountIn: BigUInt
        public let amountOut: BigUInt
        public let tonIn: BigUInt?
        public let tonOut: BigUInt?
        public let userWallet: AccountAddress
        public let router: AccountAddress
        public let jettonMasterIn: Jetton?
        public let jettonMasterOut: Jetton?
    }

    struct SmartContract: Codable {
        public let contract: AccountAddress
        public let tonAttached: BigUInt
        public let operation: String
        public let payload: String?
    }
}
