import BigInt
import Foundation
import TonSwift

class TransactionBoc {
    func create() throws -> String {
        fatalError("must be implemented by childs")
    }
}

struct TransferData {
    let contract: WalletContract
    let sender: Address
    let seqno: UInt64
    let amount: BigUInt
    let isMax: Bool
    let recipient: Address
    let isBounceable: Bool
    let comment: String?
    let timeout: UInt64?
    let signClosure: (WalletTransfer) throws -> Data
}

class TransferBoc: TransactionBoc {
    let data: TransferData

    init(transferData: TransferData) {
        data = transferData
    }
}

class TonTransferBoc: TransferBoc {
    override init(transferData: TransferData) {
        super.init(transferData: transferData)
    }

    override func create() throws -> String {
        return try TonTransferMessageBuilder.sendTonTransfer(
            contract: data.contract,
            sender: data.sender,
            seqno: data.seqno,
            value: data.amount,
            isMax: data.isMax,
            recipientAddress: data.recipient,
            isBounceable: data.isBounceable,
            comment: data.comment,
            timeout: data.timeout,
            signClosure: data.signClosure
        )
    }
}

class JettonTransferBoc: TransferBoc {
    let jetton: Address

    init(jetton: Address, transferData: TransferData) {
        self.jetton = jetton
        super.init(transferData: transferData)
    }

    override func create() throws -> String {
        return try TokenTransferMessageBuilder.sendTokenTransfer(
            contract: data.contract,
            sender: data.sender,
            seqno: data.seqno,
            tokenAddress: jetton,
            value: data.amount,
            recipientAddress: data.recipient,
            isBounceable: data.isBounceable,
            comment: data.comment,
            timeout: data.timeout,
            signClosure: data.signClosure
        )
    }
}
