import BigInt
import TonSwift

public class IncomingDecoration: TransactionDecoration {
    public let from: Address
    public let value: BigUInt
    public let comment: String?

    init(from: Address, value: BigUInt, comment: String?) {
        self.from = from
        self.value = value
        self.comment = comment
        
        super.init()
    }

    required init?(address: Address, actions: [Action]) {
        let transfers = actions.compactMap { $0 as? TonTransfer }

        let amount = IncomingDecoration.incomingAmount(address: address, transfers: transfers)
        guard amount > 0 else { return nil }

        guard let first = transfers.first(where: { $0.recipient.address == address }) else { return nil }

        self.from = first.sender.address
        self.value = BigUInt(amount)
        self.comment = first.comment

        super.init(address: address, actions: actions)
    }

    override public func tags(userAddress _: Address) -> [TransactionTag] {
        [
            TransactionTag(type: .incoming, protocol: .native, addresses: [from.toRaw()]),
        ]
    }
}

extension IncomingDecoration: CustomStringConvertible {
    public var description: String {
        [
            "Incoming",
            value.description,
            from.toRaw(),
            comment,
        ].compactMap { $0 }.joined(separator: "|")
    }
    
    static func incomingAmount(address: Address, transfers: [TonTransfer]) -> Int64 {
        let incoming = transfers.filter { $0.recipient.address == address }
        let outgoing = transfers.filter { $0.sender.address == address }
            
        return incoming.map { $0.amount }.reduce(0, +) - outgoing.map { $0.amount }.reduce(0, +)
    }
}
