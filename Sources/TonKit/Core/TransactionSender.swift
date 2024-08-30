//import BigInt
//import Foundation
//import TonSwift
//
//class TransactionSender {
//   private let api: TonApi
//   private let contract: WalletContract
//   private let sender: Address
//   private let secretKey: Data
//
//   init(api: TonApi, contract: WalletContract, sender: Address, secretKey: Data) {
//       self.api = api
//       self.contract = contract
//       self.sender = sender
//       self.secretKey = secretKey
//   }
//}
//
//public struct Amount {
//   let value: BigUInt
//   let isMax: Bool
//
//   public init(value: BigUInt, isMax: Bool) {
//       self.value = value
//       self.isMax = isMax
//   }
//}
//
//extension TransactionSender {
//   func estimatedFee(recipient: FriendlyAddress, jetton: Jetton? = nil, amount: Amount, comment: String?) async throws -> Decimal {
//       do {
//           let seqno = try await api.getSeqno(address: sender)
//           let timeout = await api.timeoutSafely()
//           let data = TransferData(
//               contract: contract,
//               sender: sender,
//               seqno: UInt64(seqno),
//               amount: amount.value,
//               isMax: amount.isMax,
//               recipient: recipient.address,
//               isBounceable: recipient.isBounceable,
//               comment: comment,
//               timeout: timeout
//           ) { transfer in
//               try transfer.signMessage(signer: WalletTransferEmptyKeySigner())
//           }
//
//           let boc: String
//           if let jetton {
//               boc = try await JettonTransferBoc(jetton: jetton.walletAddress, transferData: data).create()
//           } else {
//               boc = try await TonTransferBoc(transferData: data).create()
//           }
//           
//           let transactionInfo = try await api.emulateMessageWallet(boc: boc)
//
//           // for nfts transactionInfo.event can contains extra
//           return Decimal(transactionInfo.trace.transaction.total_fees)
//       } catch {
//           print(error)
//           return 0
//       }
//   }
//
//   func sendTransaction(recipient: FriendlyAddress, jetton: Jetton? = nil, amount: Amount, comment: String?) async throws {
//       let seqno = try await api.getSeqno(address: sender)
//       let timeout = await api.timeoutSafely()
//       let secretKey = secretKey
//
//       let data = TransferData(
//           contract: contract,
//           sender: sender,
//           seqno: UInt64(seqno),
//           amount: amount.value,
//           isMax: amount.isMax,
//           recipient: recipient.address,
//           isBounceable: recipient.isBounceable,
//           comment: comment,
//           timeout: timeout
//       ) { transfer in
//           try transfer.signMessage(signer: WalletTransferSecretKeySigner(secretKey: secretKey))
//       }
//
//       let boc: String
//       if let jetton {
//           boc = try await JettonTransferBoc(jetton: jetton.walletAddress, transferData: data).create()
//       } else {
//           boc = try await TonTransferBoc(transferData: data).create()
//       }
//
//       try await api.sendTransaction(boc: boc)
//   }
//}
