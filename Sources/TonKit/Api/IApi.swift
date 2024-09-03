import TonSwift
import BigInt

protocol IApi {
    func getAccount(address: Address) async throws -> Account
    func getAccountJettonBalances(address: Address) async throws -> [JettonBalance]
    func getEvents(address: Address, beforeLt: Int64?, startTimestamp: Int64?, limit: Int) async throws -> [Event]
    func getAccountSeqno(address: Address) async throws -> Int
    func getRawTime() async throws -> Int
    func estimateFee(boc: String) async throws -> BigUInt
    func send(boc: String) async throws
}
