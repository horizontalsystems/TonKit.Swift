import HsExtensions
import HsToolKit
import TonSwift

class AccountManager {
    private let address: Address
    private let api: IApi
    private let storage: AccountStorage
    private let logger: Logger?
    private var tasks = Set<AnyTask>()

    @DistinctPublished private(set) var account: Account?
    @DistinctPublished private(set) var syncState: SyncState = .notSynced(error: Kit.SyncError.notStarted)

    init(address: Address, api: IApi, storage: AccountStorage, logger: Logger?) {
        self.address = address
        self.api = api
        self.storage = storage
        self.logger = logger

        account = try? storage.account(address: address)
    }
}

extension AccountManager {
    func sync() {
        logger?.log(level: .debug, message: "Syncing account...")

        guard !syncState.syncing else {
            logger?.log(level: .debug, message: "Already syncing account")
            return
        }

        syncState = .syncing

        Task { [weak self, address, api] in
            do {
                let account = try await api.getAccount(address: address)
                self?.logger?.log(level: .debug, message: "Got account: \(account.balance)")

                self?.account = account
                try? self?.storage.save(account: account)
                self?.syncState = .synced
            } catch {
                self?.logger?.log(level: .error, message: "Account sync error: \(error)")
                self?.syncState = .notSynced(error: error)
            }
        }.store(in: &tasks)
    }
}
