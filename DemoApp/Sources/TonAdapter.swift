//import BigInt
//import Combine
//import Foundation
//import TonKit
//import TonSwift
//
//class TonAdapter {
//    public let tonKit: Kit
//    private let decimal = 9
//
//    init(tonKit: Kit) {
//        self.tonKit = tonKit
//    }
//
//    private func transactionRecord(fullTransaction: FullTransaction) -> TransactionRecord {
//        let transaction = fullTransaction.event
//
//        return TransactionRecord(
//            transactionHash: transaction.eventId,
//            transactionHashData: transaction.eventId.hs.data,
//            timestamp: Int(transaction.timestamp),
//            isInProgress: transaction.isInProgress,
//            lt: transaction.lt,
//            decoration: fullTransaction.decoration
//        )
//    }
//}
//
//extension TonAdapter {
//    func start() {
//        tonKit.start()
//    }
//
//    func stop() {
//        tonKit.stop()
//    }
//
//    func refresh() {
//        tonKit.refresh()
//    }
//
//    var name: String {
//        "TON"
//    }
//
//    var coin: String {
//        "TON"
//    }
//
//    var syncState: SyncState {
//        tonKit.syncState
//    }
//
//    var transactionsSyncState: SyncState {
//        tonKit.syncState
//    }
//
//    var balance: Decimal {
    //    if let significand = Decimal(string: tonKit.balance.description) {
    //        return Decimal(sign: .plus, exponent: -decimal, significand: significand)
    //    }
//
//        return 0
//    }
//
//    func jettonBalance(address: Address) -> BigUInt {
//        tonKit.jettonBalance(address: address)
//    }
//
//    func jettonBalancePublisher(address: Address) -> AnyPublisher<BigUInt, Never> {
//        tonKit.jettonBalancePublisher(address: address)
//    }
//    
//    var jettons: [Jetton] {
//        tonKit.jettons
//    }
//
//    var receiveAddress: Address {
//        tonKit.receiveAddress
//    }
//
//    var syncStatePublisher: AnyPublisher<Void, Never> {
//        tonKit.syncStatePublisher.map { _ in () }.eraseToAnyPublisher()
//    }
//
//    var transactionsSyncStatePublisher: AnyPublisher<Void, Never> {
//        tonKit.syncStatePublisher.map { _ in () }.eraseToAnyPublisher()
//    }
//
//    var balancePublisher: AnyPublisher<Void, Never> {
//        tonKit.tonBalancePublisher.map { _ in () }.eraseToAnyPublisher()
//    }
//
//    var transactionsPublisher: AnyPublisher<Void, Never> {
//        tonKit.transactionsPublisher(tagQueries: nil).map { _ in () }.eraseToAnyPublisher()
//    }
//
//    func transactions(from lt: Int64?, limit: Int?) -> [TransactionRecord] {
//        tonKit.transactions(tagQueries: [], beforeLt: lt, limit: limit).compactMap { transactionRecord(fullTransaction: $0) }
//    }
//
//    func estimateFee(recipient: String, jetton: Jetton? = nil, amount: BigUInt, comment: String?) async throws -> Decimal {
//        return try await tonKit.estimateFee(recipient: recipient, jetton: jetton, amount: amount, comment: comment)
//    }
//
//    func transaction(eventId: String) async throws -> FullTransaction {
//        try await tonKit.fetchTransaction(eventId: eventId)
//    }
//
//    func send(recipient: String, jetton: Jetton? = nil, amount: BigUInt, comment: String?) async throws {
//        try await tonKit.send(recipient: recipient, jetton: jetton, amount: amount, comment: comment)
//    }
//}
//
//extension TonAdapter {
//    enum SendError: Error {
//        case noSigner
//    }
//}
//
//extension Decimal {
//    func rounded(decimal: Int) -> Decimal {
//        let poweredDecimal = self * pow(10, decimal)
//        let handler = NSDecimalNumberHandler(roundingMode: .plain, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false)
//        return NSDecimalNumber(decimal: poweredDecimal).rounding(accordingToBehavior: handler).decimalValue / pow(10, decimal)
//    }
//}
