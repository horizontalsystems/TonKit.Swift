import BigInt
import Combine
import Foundation
import TonKit
import TonSwift

class SendViewModel: ObservableObject {
    private let tonKit: Kit

    @Published var address: String = Configuration.shared.defaultSendAddress {
        didSet {
            estimateFee()
        }
    }

    @Published var amount: String = "0.025" {
        didSet {
            estimateFee()
        }
    }

    @Published var comment: String = "" {
        didSet {
            estimateFee()
        }
    }

    @Published var estimatedFee: String?

    @Published var errorAlertText: String?
    @Published var sentAlertText: String?

    init(tonKit: Kit) {
        self.tonKit = tonKit

        estimateFee()
    }

    private func estimateFee() {
        guard let address = try? FriendlyAddress(string: address) else {
            estimatedFee = nil
            return
        }

        guard let decimalAmount = Decimal(string: amount) else {
            estimatedFee = nil
            return
        }

        guard let amount = BigUInt(Decimal(sign: .plus, exponent: 9, significand: decimalAmount).description) else {
            estimatedFee = nil
            return
        }

        let trimmedComment = comment.trimmingCharacters(in: .whitespaces)
        let comment = trimmedComment.isEmpty ? nil : trimmedComment

        Task { [weak self, tonKit] in
            let fee = try await tonKit.estimateFee(recipient: address, amount: .amount(value: amount), comment: comment)

            await MainActor.run { [weak self] in
                self?.estimatedFee = fee.tonDecimalValue.map { "\($0) TON" }
            }
        }
    }

    func send() {
        Task { [weak self, address, amount, comment, tonKit] in
            do {
                let address = try FriendlyAddress(string: address)

                guard let decimalAmount = Decimal(string: amount) else {
                    throw SendError.invalidAmount
                }

                guard let amount = BigUInt(Decimal(sign: .plus, exponent: 9, significand: decimalAmount).description) else {
                    throw SendError.invalidAmount
                }

                let trimmedComment = comment.trimmingCharacters(in: .whitespaces)
                let comment = trimmedComment.isEmpty ? nil : trimmedComment

                try await tonKit.send(recipient: address, amount: .amount(value: amount), comment: comment)

                await MainActor.run { [weak self] in
                    self?.sentAlertText = "You have successfully sent \(decimalAmount) TON to \(address.address.toFriendlyWallet)"
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.errorAlertText = "\(error)"
                }
            }
        }
    }
}

extension SendViewModel {
    enum SendError: Error {
        case invalidAmount
    }
}
