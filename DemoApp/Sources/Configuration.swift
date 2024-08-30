import HsToolKit
import TonKit

class Configuration {
    static let shared = Configuration()

    let network: Network = .testNet
    let minLogLevel: Logger.Level = .verbose

    let defaultsWords = ""
    let defaultPassphrase = ""

    let defaultsWatchAddress = ""
    let defaultSendAddress = ""

    static func isTestNet() -> Bool {
        shared.network == .testNet
    }
}
