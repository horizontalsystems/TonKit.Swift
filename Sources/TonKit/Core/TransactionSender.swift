import BigInt
import Foundation
import TonSwift

class TransactionSender {
    private let api: IApi
    private let contract: WalletContract
    private let sender: Address
    private let secretKey: Data

    init(api: IApi, contract: WalletContract, sender: Address, secretKey: Data) {
        self.api = api
        self.contract = contract
        self.sender = sender
        self.secretKey = secretKey
    }

    private func safeTimeout(TTL: UInt64 = 5 * 60) async -> UInt64 {
        do {
            let rawTime = try await api.getRawTime()
            return UInt64(rawTime) + TTL
        } catch {
            return UInt64(Date().timeIntervalSince1970) + TTL
        }
    }
}

extension TransactionSender {
    func estimateFee(recipient: FriendlyAddress, amount: Kit.SendAmount, comment: String?) async throws -> BigUInt {
        let seqno = try await api.getAccountSeqno(address: sender)
        let timeout = await safeTimeout()

        let value: BigUInt
        let isMax: Bool

        switch amount {
        case let .amount(_value):
            value = _value
            isMax = false
        case .max:
            value = 0
            isMax = true
        }

        let data = TransferData(
            contract: contract,
            sender: sender,
            seqno: UInt64(seqno),
            amount: value,
            isMax: isMax,
            recipient: recipient.address,
            isBounceable: recipient.isBounceable,
            comment: comment,
            timeout: timeout
        ) { transfer in
            try transfer.signMessage(signer: WalletTransferEmptyKeySigner())
        }

        let boc = try TonTransferBoc(transferData: data).create()

        return try await api.estimateFee(boc: boc)
    }

    func estimateFee(jetton: Jetton, recipient: FriendlyAddress, amount: BigUInt, comment: String?) async throws -> BigUInt {
        let seqno = try await api.getAccountSeqno(address: sender)
        let timeout = await safeTimeout()

        let data = TransferData(
            contract: contract,
            sender: sender,
            seqno: UInt64(seqno),
            amount: amount,
            isMax: false,
            recipient: recipient.address,
            isBounceable: recipient.isBounceable,
            comment: comment,
            timeout: timeout
        ) { transfer in
            try transfer.signMessage(signer: WalletTransferEmptyKeySigner())
        }

        let boc = try JettonTransferBoc(jetton: jetton.address, transferData: data).create()

        return try await api.estimateFee(boc: boc)
    }

    func send(recipient: FriendlyAddress, amount: Kit.SendAmount, comment: String?) async throws {
        let seqno = try await api.getAccountSeqno(address: sender)
        let timeout = await safeTimeout()
        let secretKey = secretKey

        let value: BigUInt
        let isMax: Bool

        switch amount {
        case let .amount(_value):
            value = _value
            isMax = false
        case .max:
            value = 0
            isMax = true
        }

        let data = TransferData(
            contract: contract,
            sender: sender,
            seqno: UInt64(seqno),
            amount: value,
            isMax: isMax,
            recipient: recipient.address,
            isBounceable: recipient.isBounceable,
            comment: comment,
            timeout: timeout
        ) { transfer in
            try transfer.signMessage(signer: WalletTransferSecretKeySigner(secretKey: secretKey))
        }

        let boc = try TonTransferBoc(transferData: data).create()

        return try await api.send(boc: boc)
    }

    func send(jetton: Jetton, recipient: FriendlyAddress, amount: BigUInt, comment: String?) async throws {
        let seqno = try await api.getAccountSeqno(address: sender)
        let timeout = await safeTimeout()
        let secretKey = secretKey

        let data = TransferData(
            contract: contract,
            sender: sender,
            seqno: UInt64(seqno),
            amount: amount,
            isMax: false,
            recipient: recipient.address,
            isBounceable: recipient.isBounceable,
            comment: comment,
            timeout: timeout
        ) { transfer in
            try transfer.signMessage(signer: WalletTransferSecretKeySigner(secretKey: secretKey))
        }

        let boc = try JettonTransferBoc(jetton: jetton.address, transferData: data).create()

        return try await api.send(boc: boc)
    }
}
