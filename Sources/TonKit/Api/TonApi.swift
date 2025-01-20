import BigInt
import TonAPI
import TonSwift

class TonApi: IApi {
    init(network: Network) {
        switch network {
        case .testNet: TonAPIAPI.basePath = "https://testnet.tonapi.io"
        default: ()
        }
    }

    func getAccount(address: Address) async throws -> Account {
        let account = try await AccountsAPI.getAccount(accountId: address.toRaw())

        return try Account(
            address: Address.parse(account.address),
            balance: BigUInt(account.balance),
            status: Account.Status(status: account.status)
        )
    }

    func getAccountJettonBalances(address: Address) async throws -> [JettonBalance] {
        let jettonBalances = try await AccountsAPI.getAccountJettonsBalances(accountId: address.toRaw())

        return try jettonBalances.balances.map { balance in
            try JettonBalance(
                jetton: Jetton(jettonPreview: balance.jetton),
                balance: BigUInt(balance.balance) ?? 0,
                walletAddress: Address.parse(raw: balance.walletAddress.address)
            )
        }
    }

    func getEvents(address: Address, beforeLt: Int64?, startTimestamp: Int64?, limit: Int) async throws -> [Event] {
        let events = try await AccountsAPI.getAccountEvents(accountId: address.toRaw(), limit: limit, beforeLt: beforeLt, startDate: startTimestamp)
        return try events.events.map { try Event(event: $0) }
    }

    func getAccountSeqno(address: Address) async throws -> Int {
        try await WalletAPI.getAccountSeqno(accountId: address.toRaw()).seqno
    }

    func getJettonInfo(address: Address) async throws -> Jetton {
        let jettonInfo = try await JettonsAPI.getJettonInfo(accountId: address.toRaw())
        return try Jetton(jettonInfo: jettonInfo)
    }

    func getRawTime() async throws -> Int {
        try await LiteServerAPI.getRawTime().time
    }

    func emulate(boc: String, params: [EmulateMessageToWalletRequestParamsInner]?) async throws -> EmulateResult {
        let result = try await EmulationAPI.emulateMessageToWallet(emulateMessageToWalletRequest: .init(boc: boc, params: params))
        return try EmulateResult(totalFee: BigUInt(result.trace.transaction.totalFees), event: Event(event: result.event))
    }

    func send(boc: String) async throws {
        try await BlockchainAPI.sendBlockchainMessage(sendBlockchainMessageRequest: .init(boc: boc))
    }
}

extension Event {
    init(event: AccountEvent) throws {
        id = event.eventId
        lt = event.lt
        timestamp = event.timestamp
        isScam = event.isScam
        inProgress = event.inProgress
        extra = event.extra
        actions = try event.actions.map { action in
            try Action(type: .init(action: action), status: .init(status: action.status))
        }
    }
}

extension Account.Status {
    init(status: AccountStatus) {
        switch status {
        case .nonexist: self = .nonexist
        case .uninit: self = .uninit
        case .active: self = .active
        case .frozen: self = .frozen
        case .unknownDefaultOpenApi: self = .unknown
        }
    }
}

extension Jetton {
    init(jettonPreview jetton: JettonPreview) throws {
        address = try Address.parse(raw: jetton.address)
        name = jetton.name
        symbol = jetton.symbol
        decimals = jetton.decimals
        image = jetton.image
        verification = Jetton.VerificationType(verification: jetton.verification)
    }

    init(jettonInfo jetton: JettonInfo) throws {
        address = try Address.parse(raw: jetton.metadata.address)
        name = jetton.metadata.name
        symbol = jetton.metadata.symbol
        decimals = Int(jetton.metadata.decimals) ?? 9
        image = jetton.metadata.image
        verification = Jetton.VerificationType(verification: jetton.verification)
    }
}

extension Jetton.VerificationType {
    init(verification: JettonVerificationType) {
        switch verification {
        case .whitelist: self = .whitelist
        case .blacklist: self = .blacklist
        case ._none: self = .none
        case .unknownDefaultOpenApi: self = .unknown
        }
    }
}

extension Action.`Type` {
    init(action: TonAPI.Action) throws {
        switch action.type {
        case .tonTransfer:
            if let action = action.tonTransfer {
                self = try .tonTransfer(action: .init(
                    sender: AccountAddress(accountAddress: action.sender),
                    recipient: AccountAddress(accountAddress: action.recipient),
                    amount: BigUInt(action.amount),
                    comment: action.comment
                ))
                return
            }
        case .jettonTransfer:
            if let action = action.jettonTransfer {
                self = try .jettonTransfer(action: .init(
                    sender: action.sender.map { try AccountAddress(accountAddress: $0) },
                    recipient: action.recipient.map { try AccountAddress(accountAddress: $0) },
                    sendersWallet: Address.parse(action.sendersWallet),
                    recipientsWallet: Address.parse(action.recipientsWallet),
                    amount: BigUInt(action.amount) ?? 0,
                    comment: action.comment,
                    jetton: Jetton(jettonPreview: action.jetton)
                ))
                return
            }
        case .jettonBurn:
            if let action = action.jettonBurn {
                self = try .jettonBurn(action: .init(
                    sender: AccountAddress(accountAddress: action.sender),
                    sendersWallet: Address.parse(action.sendersWallet),
                    amount: BigUInt(action.amount) ?? 0,
                    jetton: Jetton(jettonPreview: action.jetton)
                ))
                return
            }
        case .jettonMint:
            if let action = action.jettonMint {
                self = try .jettonMint(action: .init(
                    recipient: AccountAddress(accountAddress: action.recipient),
                    recipientsWallet: Address.parse(action.recipientsWallet),
                    amount: BigUInt(action.amount) ?? 0,
                    jetton: Jetton(jettonPreview: action.jetton)
                ))
                return
            }
        case .contractDeploy:
            if let action = action.contractDeploy {
                self = try .contractDeploy(action: .init(
                    address: Address.parse(action.address),
                    interfaces: action.interfaces
                ))
                return
            }
        case .jettonSwap:
            if let action = action.jettonSwap {
                self = try .jettonSwap(action: .init(
                    dex: action.dex.rawValue,
                    amountIn: BigUInt(action.amountIn) ?? 0,
                    amountOut: BigUInt(action.amountOut) ?? 0,
                    tonIn: action.tonIn.map { BigUInt($0) },
                    tonOut: action.tonOut.map { BigUInt($0) },
                    userWallet: AccountAddress(accountAddress: action.userWallet),
                    router: AccountAddress(accountAddress: action.router),
                    jettonMasterIn: action.jettonMasterIn.map { try Jetton(jettonPreview: $0) },
                    jettonMasterOut: action.jettonMasterOut.map { try Jetton(jettonPreview: $0) }
                ))
                return
            }
        case .smartContractExec:
            if let action = action.smartContractExec {
                self = try .smartContract(action: .init(
                    contract: AccountAddress(accountAddress: action.contract),
                    tonAttached: BigUInt(action.tonAttached),
                    operation: action.operation,
                    payload: action.payload
                ))
                return
            }
        default: ()
        }

        self = .unknown(rawType: action.type.rawValue)
    }
}

extension Action.Status {
    init(status: TonAPI.Action.Status) {
        switch status {
        case .ok: self = .ok
        case .failed: self = .failed
        case .unknownDefaultOpenApi: self = .unknown
        }
    }
}

extension AccountAddress {
    init(accountAddress: TonAPI.AccountAddress) throws {
        address = try Address.parse(accountAddress.address)
        name = accountAddress.name
        isScam = accountAddress.isScam
        isWallet = accountAddress.isWallet
    }
}
