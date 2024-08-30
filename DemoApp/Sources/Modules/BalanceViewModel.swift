import Combine
import Foundation
import TonKit
import TonSwift

class BalanceViewModel: ObservableObject {
    private let tonKit: Kit
    private var cancellables = Set<AnyCancellable>()

    @Published var syncState: SyncState
    @Published var account: Account?

    @Published var jettonSyncState: SyncState
    @Published var jettonBalanceMap: [Address: JettonBalance]

    @Published var eventSyncState: SyncState

    init(tonKit: Kit) {
        self.tonKit = tonKit

        syncState = tonKit.syncState
        account = tonKit.account

        jettonSyncState = tonKit.jettonSyncState
        jettonBalanceMap = tonKit.jettonBalanceMap

        eventSyncState = tonKit.eventSyncState

        tonKit.syncStatePublisher.receive(on: DispatchQueue.main).sink { [weak self] in self?.syncState = $0 }.store(in: &cancellables)
        tonKit.accountPublisher.receive(on: DispatchQueue.main).sink { [weak self] in self?.account = $0 }.store(in: &cancellables)

        tonKit.jettonSyncStatePublisher.receive(on: DispatchQueue.main).sink { [weak self] in self?.jettonSyncState = $0 }.store(in: &cancellables)
        tonKit.jettonBalanceMapPublisher.receive(on: DispatchQueue.main).sink { [weak self] in self?.jettonBalanceMap = $0 }.store(in: &cancellables)

        tonKit.eventSyncStatePublisher.receive(on: DispatchQueue.main).sink { [weak self] in self?.eventSyncState = $0 }.store(in: &cancellables)

        // print(tonKit.receiveAddress.toFriendly(testOnly: Configuration.isTestNet(), bounceable: false).toString())
    }

    var address: String {
        tonKit.receiveAddress.toFriendlyWallet
    }

    func refresh() {
        tonKit.refresh()
    }
}
