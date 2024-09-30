import BigInt
import Foundation
import TonSwift

class TransactionSender {
    private let api: IApi
    private let contract: WalletContract

    init(api: IApi, contract: WalletContract) {
        self.api = api
        self.contract = contract
    }

    private func safeTimeout(TTL: UInt64 = 5 * 60) async -> UInt64 {
        do {
            let rawTime = try await api.getRawTime()
            return UInt64(rawTime) + TTL
        } catch {
            return UInt64(Date().timeIntervalSince1970) + TTL
        }
    }

    private func boc(transferData: TransferData, signer: WalletTransferSigner) async throws -> String {
        let seqno = try await api.getAccountSeqno(address: transferData.sender)
        let timeout = await safeTimeout()

        return try ExternalMessageTransferBuilder.externalMessageTransfer(
            contract: contract,
            sender: transferData.sender,
            sendMode: transferData.sendMode,
            seqno: UInt64(seqno),
            internalMessages: transferData.internalMessages,
            timeout: timeout,
            signer: signer
        )
    }
}

extension TransactionSender {
    func emulate(trasferData: TransferData) async throws -> EmulateResult {
        let boc = try await boc(transferData: trasferData, signer: WalletTransferEmptyKeySigner())
        return try await api.emulate(boc: boc)
    }

    func send(trasferData: TransferData, secretKey: Data) async throws {
        let boc = try await boc(transferData: trasferData, signer: WalletTransferSecretKeySigner(secretKey: secretKey))
        return try await api.send(boc: boc)
    }
}
