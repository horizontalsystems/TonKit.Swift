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

    private func boc(transferData: TransferData, accountStatus: Account.Status, signer: WalletTransferSigner) async throws -> String {
        let seqno = try await api.getAccountSeqno(address: transferData.sender)
        let timeout = await safeTimeout()

        return try ExternalMessageTransferBuilder.externalMessageTransfer(
            contract: contract,
            sender: transferData.sender,
            sendMode: transferData.sendMode,
            seqno: UInt64(seqno),
            internalMessages: transferData.internalMessages,
            timeout: timeout,
            signer: signer,
            accountStatus: accountStatus
        )
    }
}

extension TransactionSender {
    func emulate(transferData: TransferData, accountStatus: Account.Status) async throws -> EmulateResult {
        let boc = try await boc(transferData: transferData, accountStatus: accountStatus, signer: WalletTransferEmptyKeySigner())
        return try await api.emulate(boc: boc)
    }

    func boc(transferData: TransferData, accountStatus: Account.Status, secretKey: Data) async throws -> String {
        try await boc(transferData: transferData, accountStatus: accountStatus, signer: WalletTransferSecretKeySigner(secretKey: secretKey))
    }

    func send(boc: String) async throws {
        return try await api.send(boc: boc)
    }
}
