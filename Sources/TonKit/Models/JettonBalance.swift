import BigInt
import Foundation
import GRDB
import TonSwift

public struct JettonBalance: Codable, Equatable, Hashable {
    public let jettonAddress: Address
    public let jetton: Jetton
    public let balance: BigUInt
    public let walletAddress: Address

    init(jetton: Jetton, balance: BigUInt, walletAddress: Address) {
        jettonAddress = jetton.address
        self.jetton = jetton
        self.balance = balance
        self.walletAddress = walletAddress
    }
}

extension JettonBalance: FetchableRecord, PersistableRecord {
    enum Columns {
        static let jettonAddress = Column(CodingKeys.jettonAddress)
        static let jetton = Column(CodingKeys.jetton)
        static let balance = Column(CodingKeys.balance)
        static let walletAddress = Column(CodingKeys.walletAddress)
    }
}
