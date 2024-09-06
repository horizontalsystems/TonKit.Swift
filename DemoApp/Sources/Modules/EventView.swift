import SwiftUI
import TonKit

struct EventView: View {
    @StateObject private var viewModel = EventViewModel()
    @ObservedObject private var appViewModel: AppViewModel

    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    HStack {
                        Text("Type")

                        Spacer()

                        Picker("Event Type", selection: $viewModel.eventType) {
                            ForEach(EventViewModel.EventType.allCases, id: \.self) { eventType in
                                Text(eventType.rawValue.capitalized)
                            }
                        }
                    }

                    HStack {
                        Text("Token")

                        Spacer()

                        Picker("Event Token", selection: $viewModel.eventToken) {
                            ForEach(viewModel.eventTokens, id: \.self) { eventToken in
                                Text(eventToken.title)
                            }
                        }
                    }

                    TextField("Address", text: $viewModel.eventAddress, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3)
                        .padding(.top, 8)
                }
                .font(.system(size: 14))
                .padding()

                Divider()

                List {
                    ForEach(viewModel.events, id: \.id) { event in
                        VStack {
                            info(title: "Id", value: event.id)
                            info(title: "Lt", value: "\(event.lt)")
                            info(title: "Timestamp", value: Date(timeIntervalSince1970: TimeInterval(event.timestamp)).formatted(date: .abbreviated, time: .standard))
                            info(title: "Scam", value: "\(event.isScam)")
                            info(title: "In Progress", value: "\(event.inProgress)")
                            info(title: "Extra", value: "\(event.extra)")

                            ForEach(event.actions.indices, id: \.self) { index in
                                let action = event.actions[index]

                                VStack {
                                    Divider()
                                        .padding(.horizontal, -16)

                                    switch action.type {
                                    case let .tonTransfer(action):
                                        tonTransfer(action: action)
                                    case let .jettonTransfer(action):
                                        jettonTransfer(action: action)
                                    case let .jettonBurn(action):
                                        jettonBurn(action: action)
                                    case let .jettonMint(action):
                                        jettonMint(action: action)
                                    case let .contractDeploy(action):
                                        contractDeploy(action: action)
                                    case let .jettonSwap(action):
                                        jettonSwap(action: action)
                                    case let .smartContract(action):
                                        smartContract(action: action)
                                    case let .unknown(rawType):
                                        actionTitle(text: rawType)
                                    }

                                    info(title: "Status", value: action.status.rawValue)
                                }
                            }
                        }
                        .listRowSeparator(.hidden)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.05))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray.opacity(0.2), lineWidth: 1))
                    }
                }
                .listStyle(.plain)
                .frame(maxHeight: .infinity)
            }
            .navigationTitle("Events")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder private func tonTransfer(action: Action.TonTransfer) -> some View {
        actionTitle(text: "Ton Transfer")
        info(title: "Sender", value: action.sender.toFriendly)
        info(title: "Recipient", value: action.recipient.toFriendly)
        info(title: "Amount", value: action.amount.tonDecimalValue.map { "\($0) TON" } ?? "n/a")

        if let comment = action.comment {
            info(title: "Comment", value: comment)
        }
    }

    @ViewBuilder private func jettonTransfer(action: Action.JettonTransfer) -> some View {
        actionTitle(text: "Jetton Transfer")
        if let sender = action.sender {
            info(title: "Sender", value: sender.toFriendly)
        }
        if let recipient = action.recipient {
            info(title: "Recipient", value: recipient.toFriendly)
        }

        info(title: "Amount", value: action.amount.decimalValue(decimals: action.jetton.decimals).map { "\($0) \(action.jetton.symbol)" } ?? "n/a")

        if let comment = action.comment {
            info(title: "Comment", value: comment)
        }

        info(title: "Jetton", value: action.jetton.address.toFriendlyContract)
    }

    @ViewBuilder private func jettonBurn(action: Action.JettonBurn) -> some View {
        actionTitle(text: "Jetton Burn")
        info(title: "Sender", value: action.sender.toFriendly)
        info(title: "Amount", value: action.amount.decimalValue(decimals: action.jetton.decimals).map { "\($0) \(action.jetton.symbol)" } ?? "n/a")
        info(title: "Jetton", value: action.jetton.address.toFriendlyContract)
    }

    @ViewBuilder private func jettonMint(action: Action.JettonMint) -> some View {
        actionTitle(text: "Jetton Mint")
        info(title: "Recipient", value: action.recipient.toFriendly)
        info(title: "Amount", value: action.amount.decimalValue(decimals: action.jetton.decimals).map { "\($0) \(action.jetton.symbol)" } ?? "n/a")
        info(title: "Jetton", value: action.jetton.address.toFriendlyContract)
    }

    @ViewBuilder private func contractDeploy(action: Action.ContractDeploy) -> some View {
        actionTitle(text: "Contract Deploy")
        info(title: "Address", value: action.address.toFriendlyContract)
        info(title: "Interfaces", value: action.interfaces.joined(separator: ", "))
    }

    @ViewBuilder private func jettonSwap(action: Action.JettonSwap) -> some View {
        actionTitle(text: "Jetton Swap")
        info(title: "Dex", value: action.dex)

        if let jetton = action.jettonMasterIn {
            info(title: "Amount In", value: action.amountIn.decimalValue(decimals: jetton.decimals).map { "\($0) \(jetton.symbol)" } ?? "n/a")
        }

        if let jetton = action.jettonMasterOut {
            info(title: "Amount Out", value: action.amountIn.decimalValue(decimals: jetton.decimals).map { "\($0) \(jetton.symbol)" } ?? "n/a")
        }

        if let tonIn = action.tonIn {
            info(title: "Ton In", value: tonIn.tonDecimalValue.map { "\($0) TON" } ?? "n/a")
        }

        if let tonOut = action.tonOut {
            info(title: "Ton Out", value: tonOut.tonDecimalValue.map { "\($0) TON" } ?? "n/a")
        }
    }

    @ViewBuilder private func smartContract(action: Action.SmartContract) -> some View {
        actionTitle(text: "Smart Contract Exec")
        info(title: "Contract", value: action.contract.toFriendly)
        info(title: "Ton Attached", value: action.tonAttached.tonDecimalValue.map { "\($0) TON" } ?? "n/a")
        info(title: "Operation", value: action.operation)

        if let payload = action.payload {
            info(title: "Payload", value: payload)
        }
    }

    @ViewBuilder private func info(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(title):")
                .font(.system(size: 12))

            Spacer()

            Text(value)
                .font(.system(size: 11))
                .lineLimit(1)
                .truncationMode(.middle)
                .multilineTextAlignment(.trailing)
        }
    }

    @ViewBuilder private func actionTitle(text: String) -> some View {
        Text("[ \(text) ]")
            .font(.system(size: 12))
            .padding(.bottom, 8)
    }
}
