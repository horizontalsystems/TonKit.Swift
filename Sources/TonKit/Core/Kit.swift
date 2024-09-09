import BigInt
import Combine
import Foundation
import GRDB
import HsCryptoKit
import HsToolKit
import TonAPI
import TonStreamingAPI
import TonSwift

public class Kit {
    private let address: Address

    private let apiListener: IApiListener
    private let accountManager: AccountManager
    private let jettonManager: JettonManager
    private let eventManager: EventManager
    private let transactionSender: TransactionSender?
    private let logger: Logger?
    private var cancellables = Set<AnyCancellable>()

    init(address: Address, apiListener: IApiListener, accountManager: AccountManager, jettonManager: JettonManager, eventManager: EventManager, transactionSender: TransactionSender?, logger: Logger?) {
        self.address = address
        self.apiListener = apiListener
        self.accountManager = accountManager
        self.jettonManager = jettonManager
        self.eventManager = eventManager
        self.transactionSender = transactionSender
        self.logger = logger

        apiListener.transactionPublisher
            .sink { [weak self] in self?.sync() }
            .store(in: &cancellables)
    }
}

// Public API Extension

public extension Kit {
    var watchOnly: Bool {
        transactionSender == nil
    }

    var syncState: SyncState {
        accountManager.syncState
    }

    var syncStatePublisher: AnyPublisher<SyncState, Never> {
        accountManager.$syncState.eraseToAnyPublisher()
    }

    var jettonSyncState: SyncState {
        jettonManager.syncState
    }

    var jettonSyncStatePublisher: AnyPublisher<SyncState, Never> {
        jettonManager.$syncState.eraseToAnyPublisher()
    }

    var eventSyncState: SyncState {
        eventManager.syncState
    }

    var eventSyncStatePublisher: AnyPublisher<SyncState, Never> {
        eventManager.$syncState.eraseToAnyPublisher()
    }

    var account: Account? {
        accountManager.account
    }

    var accountPublisher: AnyPublisher<Account?, Never> {
        accountManager.$account.eraseToAnyPublisher()
    }

    var jettonBalanceMap: [Address: JettonBalance] {
        jettonManager.jettonBalanceMap
    }

    var jettonBalanceMapPublisher: AnyPublisher<[Address: JettonBalance], Never> {
        jettonManager.$jettonBalanceMap.eraseToAnyPublisher()
    }

    var receiveAddress: Address {
        address
    }

    func events(tagQuery: TagQuery, beforeLt: Int64? = nil, limit: Int? = nil) -> [Event] {
        eventManager.events(tagQuery: tagQuery, beforeLt: beforeLt, limit: limit)
    }

    func eventPublisher(tagQuery: TagQuery) -> AnyPublisher<EventInfo, Never> {
        eventManager.eventPublisher(tagQuery: tagQuery)
    }

    func tagTokens() -> [TagToken] {
        eventManager.tagTokens()
    }

    func estimateFee(recipient: FriendlyAddress, amount: SendAmount, comment: String?) async throws -> BigUInt {
        guard let transactionSender else {
            throw WalletError.watchOnly
        }

        return try await transactionSender.estimateFee(recipient: recipient, amount: amount, comment: comment)
    }

    func estimateFee(jettonWallet: Address, recipient: FriendlyAddress, amount: BigUInt, comment: String?) async throws -> BigUInt {
        guard let transactionSender else {
            throw WalletError.watchOnly
        }

        return try await transactionSender.estimateFee(jettonWallet: jettonWallet, recipient: recipient, amount: amount, comment: comment)
    }

    func send(recipient: FriendlyAddress, amount: SendAmount, comment: String?) async throws {
        guard let transactionSender else {
            throw WalletError.watchOnly
        }

        return try await transactionSender.send(recipient: recipient, amount: amount, comment: comment)
    }

    func send(jettonWallet: Address, recipient: FriendlyAddress, amount: BigUInt, comment: String?) async throws {
        guard let transactionSender else {
            throw WalletError.watchOnly
        }

        return try await transactionSender.send(jettonWallet: jettonWallet, recipient: recipient, amount: amount, comment: comment)
    }

    func startListener() {
        apiListener.start(address: address)
    }

    func stopListener() {
        apiListener.stop()
    }

    func sync() {
        accountManager.sync()
        jettonManager.sync()
        eventManager.sync()
    }

    static func validate(address: String) throws {
        _ = try Address.parse(address)
    }
}

public extension Kit {
    static func clear(exceptFor excludedFiles: [String]) throws {
        let fileManager = FileManager.default
        let fileUrls = try fileManager.contentsOfDirectory(at: dataDirectoryUrl(), includingPropertiesForKeys: nil)

        for filename in fileUrls {
            if !excludedFiles.contains(where: { filename.lastPathComponent.contains($0) }) {
                try fileManager.removeItem(at: filename)
            }
        }
    }

    static func instance(type: WalletType, walletVersion: WalletVersion = .v4, network: Network = .mainNet, walletId: String, minLogLevel: Logger.Level = .error) throws -> Kit {
        let logger = Logger(minLogLevel: minLogLevel)
        let uniqueId = "\(walletId)-\(network.rawValue)"

        // let reachabilityManager = ReachabilityManager()
        let databaseURL = try dataDirectoryUrl().appendingPathComponent("ton-\(uniqueId).sqlite")

        let dbPool = try DatabasePool(path: databaseURL.path)

        let api = api(network: network)

        let address: Address
        var transactionSender: TransactionSender?

        switch type {
        case let .full(keyPair):
            let walletContract: WalletContract

            switch walletVersion {
            case .v3:
                fatalError() // todo
            case .v4:
                walletContract = WalletV4R2(publicKey: keyPair.publicKey.data)
            case .v5:
                fatalError() // todo
            }

            address = try walletContract.address()
            transactionSender = TransactionSender(api: api, contract: walletContract, sender: address, secretKey: keyPair.privateKey.data)
        case let .watch(_address):
            address = _address
        }

        let apiListener: IApiListener = TonApiListener(network: network, logger: logger)

        let accountStorage = try AccountStorage(dbPool: dbPool)
        let accountManager = AccountManager(address: address, api: api, storage: accountStorage, logger: logger)

        let jettonStorage = try JettonStorage(dbPool: dbPool)
        let jettontManager = JettonManager(address: address, api: api, storage: jettonStorage, logger: logger)

        let eventStorage = try EventStorage(dbPool: dbPool)
        let eventManager = EventManager(address: address, api: api, storage: eventStorage, logger: logger)

        let kit = Kit(
            address: address,
            apiListener: apiListener,
            accountManager: accountManager,
            jettonManager: jettontManager,
            eventManager: eventManager,
            transactionSender: transactionSender,
            logger: logger
        )

        return kit
    }

    static func jetton(network: Network = .mainNet, address: Address) async throws -> Jetton {
        try await api(network: network).getJettonInfo(address: address)
    }

    private static func api(network: Network) -> IApi {
        TonApi(network: network)
    }

    private static func dataDirectoryUrl() throws -> URL {
        let fileManager = FileManager.default

        let url = try fileManager
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("ton-kit", isDirectory: true)

        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)

        return url
    }
}

public extension Kit {
    enum WalletType {
        case full(KeyPair)
        case watch(Address)
    }

    enum WalletVersion {
        case v3
        case v4
        case v5
    }

    enum SyncError: Error {
        case notStarted
    }

    enum WalletError: Error {
        case watchOnly
    }

    enum SendAmount {
        case amount(value: BigUInt)
        case max
    }
}
