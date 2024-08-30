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

        return try events.events.map { event in
            try Event(
                id: event.eventId,
                lt: event.lt,
                timestamp: event.timestamp,
                isScam: event.isScam,
                inProgress: event.inProgress,
                actions: event.actions.map { action in
                    try Action(type: .init(action: action), status: .init(status: action.status))
                }
            )
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

// // MARK: - Account

// extension TonApi {
//     func getAccountInfo(address: Address) async throws -> Account {
//         try await AccountsAPI.getAccountJettonBalance(accountId: String, jettonId: String)
//         let response = try await tonAPIClient
//             .getAccount(.init(path: .init(account_id: address.toRaw())))
//         return try Account(account: response.ok.body.json)
//     }

//     func getAccountJettonsBalances(address: Address, currencies: [String]) async throws -> [JettonBalance] {
//         let currenciesString = currencies.joined(separator: ",")
//         let response = try await tonAPIClient
//             .getAccountJettonsBalances(path: .init(account_id: address.toRaw()), query: .init(currencies: currenciesString))
//         return try response.ok.body.json.balances
//             .compactMap { jetton in
//                 do {
//                     let quantity = BigUInt(stringLiteral: jetton.balance)
//                     let walletAddress = try Address.parse(jetton.wallet_address.address)
//                     let jettonInfo = try JettonInfo(jettonPreview: jetton.jetton)
//                     let jettonItem = JettonItem(jettonInfo: jettonInfo, walletAddress: walletAddress)
//                     let jettonBalance = JettonBalance(item: jettonItem, quantity: quantity)
//                     return jettonBalance
//                 } catch {
//                     return nil
//                 }
//             }
//     }
// }

// //// MARK: - Events

// extension TonApi {
//     func getAccountEvents(address: Address,
//                           beforeLt: Int64?,
//                           limit: Int,
//                           start: Int64? = nil,
//                           end: Int64? = nil) async throws -> AccountEvents
//     {
//         let response = try await tonAPIClient.getAccountEvents(
//             path: .init(account_id: address.toRaw()),
//             query: .init(before_lt: beforeLt,
//                          limit: limit,
//                          start_date: start,
//                          end_date: end)
//         )
//         let entity = try response.ok.body.json
//         let events: [AccountEvent] = entity.events.compactMap {
//             guard let activityEvent = try? AccountEvent(accountEvent: $0) else { return nil }
//             return activityEvent
//         }
//         return AccountEvents(address: address,
//                              events: events,
//                              startFrom: beforeLt ?? 0,
//                              nextFrom: entity.next_from)
//     }

//     func getAccountJettonEvents(address: Address,
//                                 jettonInfo: JettonInfo,
//                                 beforeLt: Int64?,
//                                 limit: Int,
//                                 start: Int64? = nil,
//                                 end: Int64? = nil) async throws -> AccountEvents
//     {
//         let response = try await tonAPIClient.getAccountJettonHistoryByID(
//             path: .init(account_id: address.toRaw(),
//                         jetton_id: jettonInfo.address.toRaw()),
//             query: .init(before_lt: beforeLt,
//                          limit: limit,
//                          start_date: start,
//                          end_date: end)
//         )
//         let entity = try response.ok.body.json
//         let events: [AccountEvent] = entity.events.compactMap {
//             guard let activityEvent = try? AccountEvent(accountEvent: $0) else { return nil }
//             return activityEvent
//         }
//         return AccountEvents(address: address,
//                              events: events,
//                              startFrom: beforeLt ?? 0,
//                              nextFrom: entity.next_from)
//     }

//     func getEvent(address: Address,
//                   eventId: String) async throws -> AccountEvent
//     {
//         let response = try await tonAPIClient
//             .getAccountEvent(path: .init(account_id: address.toRaw(),
//                                          event_id: eventId))
//         return try AccountEvent(accountEvent: response.ok.body.json)
//     }
// }

// // MARK: - Wallet

// extension TonApi {
//     func getSeqno(address: Address) async throws -> Int {
//         let response = try await tonAPIClient
//             .getAccountSeqno(path: .init(account_id: address.toRaw()))
//         return try response.ok.body.json.seqno
//     }

//     func emulateMessageWallet(boc: String) async throws -> Components.Schemas.MessageConsequences {
//         let response = try await tonAPIClient
//             .emulateMessageToWallet(body: .json(.init(boc: boc)))
//         return try response.ok.body.json
//     }

//     func sendTransaction(boc: String) async throws {
//         let response = try await tonAPIClient
//             .sendBlockchainMessage(body: .json(.init(boc: boc)))
//         _ = try response.ok
//     }
// }

// //// MARK: - NFTs
// //
// // extension TonApi {
// //    func getAccountNftItems(address: Address,
// //                            collectionAddress: Address?,
// //                            limit: Int?,
// //                            offset: Int?,
// //                            isIndirectOwnership: Bool) async throws -> [Nft]
// //    {
// //        let response = try await tonAPIClient.getAccountNftItems(
// //            path: .init(account_id: address.toRaw()),
// //            query: .init(collection: collectionAddress?.toRaw(),
// //                         limit: limit,
// //                         offset: offset,
// //                         indirect_ownership: isIndirectOwnership)
// //        )
// //        let entity = try response.ok.body.json
// //        let collectibles = entity.nft_items.compactMap {
// //            try? Nft(nftItem: $0)
// //        }
// //
// //        return collectibles
// //    }
// //
// //    func getNftItemsByAddresses(_ addresses: [Address]) async throws -> [Nft] {
// //        let response = try await tonAPIClient
// //            .getNftItemsByAddresses(
// //                .init(
// //                    body: .json(.init(account_ids: addresses.map { $0.toRaw() })))
// //            )
// //        let entity = try response.ok.body.json
// //        let nfts = entity.nft_items.compactMap {
// //            try? Nft(nftItem: $0)
// //        }
// //        return nfts
// //    }
// // }

// // MARK: - Jettons

// extension TonApi {
//     func resolveJetton(address: Address) async throws -> JettonInfo {
//         let response = try await tonAPIClient.getJettonInfo(
//             Operations.getJettonInfo.Input(
//                 path: Operations.getJettonInfo.Input.Path(
//                     account_id: address.toRaw()
//                 )
//             )
//         )
//         let entity = try response.ok.body.json
//         let verification: JettonInfo.Verification
//         switch entity.verification {
//         case .none:
//             verification = .none
//         case .blacklist:
//             verification = .blacklist
//         case .whitelist:
//             verification = .whitelist
//         }

//         return try JettonInfo(
//             address: Address.parse(entity.metadata.address),
//             fractionDigits: Int(entity.metadata.decimals) ?? 0,
//             name: entity.metadata.name,
//             symbol: entity.metadata.symbol,
//             verification: verification,
//             imageURL: URL(string: entity.metadata.image ?? "")
//         )
//     }
// }

// //// MARK: - DNS
// //
// // extension TonApi {
// //  enum DNSError: Swift.Error {
// //    case noWalletData
// //  }
// //
// //  func resolveDomainName(_ domainName: String) async throws -> FriendlyAddress {
// //    let response = try await tonAPIClient.dnsResolve(path: .init(domain_name: domainName))
// //    let entity = try response.ok.body.json
// //    guard let wallet = entity.wallet else {
// //      throw DNSError.noWalletData
// //    }
// //
// //    let address = try Address.parse(wallet.address)
// //    return FriendlyAddress(address: address, bounceable: !wallet.is_wallet)
// //  }
// //
// //  func getDomainExpirationDate(_ domainName: String) async throws -> Date? {
// //    let response = try await tonAPIClient.getDnsInfo(path: .init(domain_name: domainName))
// //    let entity = try response.ok.body.json
// //    guard let expiringAt = entity.expiring_at else { return nil }
// //    return Date(timeIntervalSince1970: TimeInterval(integerLiteral: Int64(expiringAt)))
// //  }
// // }
// //
// // extension TonApi {
// //  enum APIError: Swift.Error {
// //    case incorrectResponse
// //    case serverError(statusCode: Int)
// //  }
// // }

// // MARK: - Time

// extension TonApi {
//     func time() async throws -> TimeInterval {
//         let response = try await tonAPIClient.getRawTime(Operations.getRawTime.Input())
//         let entity = try response.ok.body.json
//         return TimeInterval(entity.time)
//     }

//     func timeoutSafely(TTL: UInt64 = 5 * 60) async -> UInt64 {
//         do {
//             let time = try await time()
//             return UInt64(time) + TTL
//         } catch {
//             return UInt64(Date().timeIntervalSince1970) + TTL
//         }
//     }
// }
