import Combine
import TonKit

class ReceiveViewModel: ObservableObject {
    var address: String {
        Singleton.tonKit?.receiveAddress.toFriendlyWallet ?? ""
    }
}
