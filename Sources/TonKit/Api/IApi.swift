import BigInt
import TonAPI
import TonSwift

protocol IApi {
    func getAccount(address: Address) async throws -> Account
    func getAccountJettonBalances(address: Address) async throws -> [JettonBalance]
    func getEvents(address: Address, beforeLt: Int64?, startTimestamp: Int64?, limit: Int) async throws -> [Event]
    func getAccountSeqno(address: Address) async throws -> Int
    func getJettonInfo(address: Address) async throws -> Jetton
    func getRawTime() async throws -> Int
    func emulate(boc: String, params: [EmulateMessageToWalletRequestParamsInner]?) async throws -> EmulateResult
    func send(boc: String) async throws
}
