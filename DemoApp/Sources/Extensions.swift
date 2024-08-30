import BigInt
import Foundation
import TonSwift
import TonKit

extension String: Identifiable {
    public typealias ID = Int
    public var id: Int {
        return hash
    }
}

extension BigUInt {
    var tonDecimalValue: Decimal? {
        guard let significand = Decimal(string: description) else {
            return nil
        }

        return Decimal(sign: .plus, exponent: -9, significand: significand)
    }

    func decimalValue(decimals: Int) -> Decimal? {
        guard let significand = Decimal(string: description) else {
            return nil
        }

        return Decimal(sign: .plus, exponent: -decimals, significand: significand)
    }
}

extension Address {
    var toFriendlyWallet: String {
        toFriendly(testOnly: Configuration.isTestNet(), bounceable: false).toString()
    }

    var toFriendlyContract: String {
        toFriendly(testOnly: Configuration.isTestNet(), bounceable: true).toString()
    }
}

extension AccountAddress {
    var toFriendly: String {
        isWallet ? address.toFriendlyWallet : address.toFriendlyContract
    }   
}
