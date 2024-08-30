import HsExtensions
import HsToolKit
import TonSwift

class JettonManager {
    private let address: Address
    private let api: IApi
    private let storage: JettonStorage
    private let logger: Logger?
    private var tasks = Set<AnyTask>()

    @DistinctPublished private(set) var jettonBalanceMap: [Address: JettonBalance]
    @DistinctPublished private(set) var syncState: SyncState = .notSynced(error: Kit.SyncError.notStarted)

    init(address: Address, api: IApi, storage: JettonStorage, logger: Logger?) {
        self.address = address
        self.api = api
        self.storage = storage
        self.logger = logger

        do {
            let jettonBalances = try storage.jettonBalances()
            jettonBalanceMap = jettonBalances.reduce(into: [:]) { $0[$1.jetton.address] = $1 }
        } catch {
            jettonBalanceMap = [:]
        }
    }
}

extension JettonManager {
    func sync() {
        logger?.log(level: .debug, message: "Syncing jetton balances...")

        guard !syncState.syncing else {
            logger?.log(level: .debug, message: "Already syncing jetton balances")
            return
        }

        syncState = .syncing

        Task { [weak self, address, api] in
            do {
                let jettonBalances = try await api.getAccountJettonBalances(address: address)
                self?.logger?.log(level: .debug, message: "Got jetton balances: \(jettonBalances.count)")

                self?.jettonBalanceMap = jettonBalances.reduce(into: [:]) { $0[$1.jetton.address] = $1 }
                try? self?.storage.update(jettonBalances: jettonBalances)
                self?.syncState = .synced
            } catch {
                self?.logger?.log(level: .error, message: "Jetton balances sync error: \(error)")
                self?.syncState = .notSynced(error: error)
            }
        }.store(in: &tasks)
    }
}
