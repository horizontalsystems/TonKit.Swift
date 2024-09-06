import BigInt
import Combine
import Foundation
import TonKit
import TonSwift

class SendViewModel: ObservableObject {
    @Published var token: Token = .native

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

    init() {
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

        Task { [weak self, token] in
            let fee: BigUInt

            switch token {
            case .native:
                fee = try await Singleton.tonKit?.estimateFee(recipient: address, amount: .amount(value: amount), comment: comment) ?? 0
            case let .jetton(jettonBalance):
                fee = try await Singleton.tonKit?.estimateFee(jettonWallet: jettonBalance.walletAddress, recipient: address, amount: amount, comment: comment) ?? 0
            }

            await MainActor.run { [weak self] in
                self?.estimatedFee = fee.tonDecimalValue.map { "\($0) TON" }
            }
        }
    }

    var tokens: [Token] {
        guard let tonKit = Singleton.tonKit else {
            return []
        }

        let jettons: [Token] = tonKit.jettonBalanceMap.values.map { jettonBalance in
            .jetton(jettonBalance: jettonBalance)
        }

        return [.native] + jettons
    }

    func send() {
        Task { [weak self, token, address, amount, comment] in
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

                let successMessage: String

                switch token {
                case .native:
                    try await Singleton.tonKit?.send(recipient: address, amount: .amount(value: amount), comment: comment)
                    successMessage = "You have successfully sent \(decimalAmount) TON to \(address.address.toFriendlyWallet)"
                case let .jetton(jettonBalance):
                    try await Singleton.tonKit?.send(jettonWallet: jettonBalance.walletAddress, recipient: address, amount: amount, comment: comment)
                    successMessage = "You have successfully sent \(decimalAmount) \(jettonBalance.jetton.symbol) to \(address.address.toFriendlyWallet)"
                }

                await MainActor.run { [weak self] in
                    self?.sentAlertText = successMessage
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
    enum Token: Hashable {
        case native
        case jetton(jettonBalance: JettonBalance)

        var title: String {
            switch self {
            case .native: return "TON"
            case let .jetton(jettonBalance): return jettonBalance.jetton.symbol
            }
        }
    }

    enum SendError: Error {
        case invalidAmount
    }
}
