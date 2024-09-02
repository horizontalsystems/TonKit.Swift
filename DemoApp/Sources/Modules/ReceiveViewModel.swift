import Combine
import TonKit

class ReceiveViewModel: ObservableObject {
    private let tonKit: Kit

    init(tonKit: Kit) {
        self.tonKit = tonKit
    }

    var address: String {
        tonKit.receiveAddress.toFriendlyWallet
    }
}
