import Combine
import Foundation
import HsToolKit
import TonKit
import TonSwift
import TweetNacl

struct Singleton {
    static var tonKit: Kit?
}

enum AppError: Error {
    case noTonKit
}

class AppViewModel: ObservableObject {
    private let keyWords = "mnemonic_words"
    private let keyAddress = "address"

    @Published var tonKit: Kit?

    init() {
        if let words = savedWords {
            try? initKit(words: words)
        } else if let address = savedAddress {
            try? initKit(address: address)
        }
    }

    private func initKit(type: Kit.WalletType) throws {
        let configuration = Configuration.shared

        let tonKit = try Kit.instance(
            type: type,
            walletVersion: .v4,
            network: configuration.network,
            walletId: "wallet-id",
            minLogLevel: configuration.minLogLevel
        )

        tonKit.sync()
        tonKit.startListener()

        Singleton.tonKit = tonKit
        self.tonKit = tonKit
    }

    private func initKit(words: [String]) throws {
        let keyPair = try Mnemonic.mnemonicToPrivateKey(mnemonicArray: words)
        try initKit(type: .full(keyPair))
    }

    private func initKit(address: Address) throws {
        try initKit(type: .watch(address))
    }

    private var savedWords: [String]? {
        guard let wordsString = UserDefaults.standard.value(forKey: keyWords) as? String else {
            return nil
        }

        return wordsString.split(separator: " ").map(String.init)
    }

    private var savedAddress: Address? {
        guard let addressString = UserDefaults.standard.value(forKey: keyAddress) as? String else {
            return nil
        }

        return try? Address.parse(raw: addressString)
    }

    private func save(words: [String]) {
        UserDefaults.standard.set(words.joined(separator: " "), forKey: keyWords)
        UserDefaults.standard.synchronize()
    }

    private func save(address: String) {
        UserDefaults.standard.set(address, forKey: keyAddress)
        UserDefaults.standard.synchronize()
    }

    private func clearStorage() {
        UserDefaults.standard.removeObject(forKey: keyWords)
        UserDefaults.standard.removeObject(forKey: keyAddress)
        UserDefaults.standard.synchronize()
    }
}

extension AppViewModel {
    func login(words: [String]) throws {
        try Kit.clear(exceptFor: [])

        try initKit(words: words)
        save(words: words)
    }

    func watch(address addressString: String) throws {
        try Kit.clear(exceptFor: [])

        let address = try Address.parse(addressString)
        try initKit(address: address)
        save(address: address.toRaw())
    }

    func logout() {
        clearStorage()

        tonKit = nil
        Singleton.tonKit = nil
    }
}

extension AppViewModel {
    enum LoginError: Error {
        case emptyWords
        case seedGenerationFailed
    }
}
