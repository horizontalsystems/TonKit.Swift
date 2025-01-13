import Foundation
import TonSwift

public struct ExternalMessageTransferBuilder {
    private init() {}

    public static func externalMessageTransfer(
        contract: WalletContract,
        sender: Address,
        sendMode: SendMode = .walletDefault(),
        seqno: UInt64,
        internalMessages: [MessageRelaxed],
        timeout: UInt64?,
        signer: WalletTransferSigner,
        accountStatus: Account.Status
    ) throws -> String {
        let transferData = WalletTransferData(
            seqno: seqno,
            messages: internalMessages,
            sendMode: sendMode,
            timeout: timeout
        )

        let transfer = try contract.createTransfer(args: transferData, messageType: .ext)
        let signedTransfer = try transfer.signMessage(signer: signer)
        let body = Builder()
        try body.store(data: signedTransfer)
        try body.store(transfer.signingMessage)
        let transferCell = try body.endCell()

        let externalMessage = Message.external(
            to: sender,
            stateInit: accountStatus.stateInitRequired ? contract.stateInit : nil,
            body: transferCell
        )

        let cell = try Builder().store(externalMessage).endCell()
        return try cell.toBoc().base64EncodedString()
    }
}
