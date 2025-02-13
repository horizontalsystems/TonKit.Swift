import BigInt
import Foundation
import TonAPI
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
        var timeout = await safeTimeout()
        let account = try await api.getAccount(address: transferData.sender)

        if let validUntil = transferData.validUntil {
            timeout = min(timeout, UInt64(validUntil))
        }

        return try ExternalMessageTransferBuilder.externalMessageTransfer(
            contract: contract,
            sender: transferData.sender,
            sendMode: transferData.sendMode,
            seqno: UInt64(seqno),
            internalMessages: transferData.internalMessages,
            timeout: timeout,
            signer: signer,
            accountStatus: account.status
        )
    }
}

extension TransactionSender {
    func emulate(transferData: TransferData) async throws -> EmulateResult {
        let boc = try await boc(transferData: transferData, signer: WalletTransferEmptyKeySigner())
        let params: [EmulateMessageToWalletRequestParamsInner] = [.init(address: transferData.sender.toString(), balance: 1_000_000_000)]
        return try await api.emulate(boc: boc, params: params)
    }

    func boc(transferData: TransferData, secretKey: Data) async throws -> String {
        try await boc(transferData: transferData, signer: WalletTransferSecretKeySigner(secretKey: secretKey))
    }

    func send(boc: String) async throws {
        return try await api.send(boc: boc)
    }
}
