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
    // private var cancellables = Set<AnyCancellable>()

    private let address: Address
    private let network: Network

    private let accountManager: AccountManager
    private let jettonManager: JettonManager
    private let eventManager: EventManager
    private let transactionSender: TransactionSender?

    private let logger: Logger?

    // @Published public var updateState: String = "idle"

    init(address: Address, network: Network, accountManager: AccountManager, jettonManager: JettonManager, eventManager: EventManager, transactionSender: TransactionSender?, logger: Logger?) {
        self.address = address
        self.network = network
        self.accountManager = accountManager
        self.jettonManager = jettonManager
        self.eventManager = eventManager
        self.transactionSender = transactionSender
        self.logger = logger
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

    func eventPublisher(tagQuery: TagQuery) -> AnyPublisher<[Event], Never> {
        eventManager.eventPublisher(tagQuery: tagQuery)
    }

    func estimateFee(recipient: FriendlyAddress, amount: SendAmount, comment: String?) async throws -> BigUInt {
        guard let transactionSender else {
            throw WalletError.watchOnly
        }

        return try await transactionSender.estimateFee(recipient: recipient, amount: amount, comment: comment)
    }

    func estimateFee(jetton: Jetton, recipient: FriendlyAddress, amount: BigUInt, comment: String?) async throws -> BigUInt {
        guard let transactionSender else {
            throw WalletError.watchOnly
        }

        return try await transactionSender.estimateFee(jetton: jetton, recipient: recipient, amount: amount, comment: comment)
    }

    func send(recipient: FriendlyAddress, amount: SendAmount, comment: String?) async throws {
        guard let transactionSender else {
            throw WalletError.watchOnly
        }

        return try await transactionSender.send(recipient: recipient, amount: amount, comment: comment)
    }

    func send(jetton: Jetton, recipient: FriendlyAddress, amount: BigUInt, comment: String?) async throws {
        guard let transactionSender else {
            throw WalletError.watchOnly
        }

        return try await transactionSender.send(jetton: jetton, recipient: recipient, amount: amount, comment: comment)
    }

    func start() {
        // syncer.start()
    }

    func stop() {
        // syncer.stop()
    }

    func refresh() {
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

    static func instance(type: WalletType, walletVersion: WalletVersion = .v4, network: Network = .mainNet, walletId: String, logger: Logger? = nil) throws -> Kit {
        let uniqueId = "\(walletId)-\(network.rawValue)"

        // let reachabilityManager = ReachabilityManager()
        let databaseURL = try dataDirectoryUrl().appendingPathComponent("ton-\(uniqueId).sqlite")

        let dbPool = try DatabasePool(path: databaseURL.path)

        let api: IApi = TonApi(network: network)

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

        let accountStorage = try AccountStorage(dbPool: dbPool)
        let accountManager = AccountManager(address: address, api: api, storage: accountStorage, logger: logger)

        let jettonStorage = try JettonStorage(dbPool: dbPool)
        let jettontManager = JettonManager(address: address, api: api, storage: jettonStorage, logger: logger)

        let eventStorage = try EventStorage(dbPool: dbPool)
        let eventManager = EventManager(address: address, api: api, storage: eventStorage, logger: logger)

        let kit = Kit(
            address: address,
            network: network,
            accountManager: accountManager,
            jettonManager: jettontManager,
            eventManager: eventManager,
            transactionSender: transactionSender,
            logger: logger
        )

        return kit
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
        // case noNetworkConnection
        // case disconnected
    }

    enum WalletError: Error {
        case watchOnly
    }

    enum SendAmount {
        case amount(value: BigUInt)
        case max
    }
}
