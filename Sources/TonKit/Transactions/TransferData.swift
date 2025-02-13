import Foundation
import TonSwift

public struct TransferData {
    public let sender: Address
    public let sendMode: SendMode
    public let validUntil: TimeInterval?
    public let internalMessages: [MessageRelaxed]
}
