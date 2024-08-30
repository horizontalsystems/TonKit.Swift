import TonSwift

protocol IApi {
    func getAccount(address: Address) async throws -> Account
    func getAccountJettonBalances(address: Address) async throws -> [JettonBalance]
    func getEvents(address: Address, beforeLt: Int64?, startTimestamp: Int64?, limit: Int) async throws -> [Event]
}
