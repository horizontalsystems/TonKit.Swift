import BigInt
import Combine
import Foundation
import TonKit
import TonSwift

class SendViewModel: ObservableObject {
    @Published var token: Token = .native

    @Published var address: String = Configuration.shared.defaultSendAddress {
        didSet {
            // emulate()
        }
    }

    @Published var amount: String = "0.025" {
        didSet {
            // emulate()
        }
    }

    @Published var comment: String = "" {
        didSet {
            // emulate()
        }
    }

    @Published var estimatedFee: String?

    @Published var errorAlertText: String?
    @Published var sentAlertText: String?

    init() {
        // emulate()
    }

    func emulate() {
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

        guard let tonKit = Singleton.tonKit, let keyPair = Singleton.keyPair else {
            estimatedFee = nil
            return
        }

        let transferData: TransferData

        do {
            switch token {
            case .native:
                transferData = try tonKit.transferData(recipient: address, amount: .amount(value: amount), comment: comment)
            case let .jetton(jettonBalance):
                transferData = try tonKit.transferData(jettonAddress: jettonBalance.jettonAddress, recipient: address, amount: amount, comment: comment)
            }
        } catch {
            estimatedFee = nil
            return
        }

        Task { [weak self] in
            do {
                let contract = WalletV4R2(publicKey: keyPair.publicKey.data)
                let result = try await TonKit.Kit.emulate(transferData: transferData, contract: contract, network: Configuration.shared.network)

                await MainActor.run { [weak self] in
                    self?.estimatedFee = result.totalFee.tonDecimalValue.map { "\($0) TON" }
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.estimatedFee = nil
                }
                print("EMULATE ERROR: \(error)")
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
                guard let tonKit = Singleton.tonKit, let keyPair = Singleton.keyPair else {
                    throw SendError.noKeyPair
                }

                let address = try FriendlyAddress(string: address)

                guard let decimalAmount = Decimal(string: amount) else {
                    throw SendError.invalidAmount
                }

                guard let amount = BigUInt(Decimal(sign: .plus, exponent: 9, significand: decimalAmount).description) else {
                    throw SendError.invalidAmount
                }

                let trimmedComment = comment.trimmingCharacters(in: .whitespaces)
                let comment = trimmedComment.isEmpty ? nil : trimmedComment

                let transferData: TransferData
                let successMessage: String

                switch token {
                case .native:
                    transferData = try tonKit.transferData(recipient: address, amount: .amount(value: amount), comment: comment)
                    successMessage = "You have successfully sent \(decimalAmount) TON to \(address.address.toFriendlyWallet)"
                case let .jetton(jettonBalance):
                    transferData = try tonKit.transferData(jettonAddress: jettonBalance.jettonAddress, recipient: address, amount: amount, comment: comment)
                    successMessage = "You have successfully sent \(decimalAmount) \(jettonBalance.jetton.symbol) to \(address.address.toFriendlyWallet)"
                }

                let contract = WalletV4R2(publicKey: keyPair.publicKey.data)
                let boc = try await TonKit.Kit.boc(transferData: transferData, contract: contract, secretKey: keyPair.privateKey.data, network: Configuration.shared.network)
                try await TonKit.Kit.send(boc: boc, contract: contract, network: Configuration.shared.network)

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
        case noKeyPair
        case invalidAmount
    }
}
