import SwiftUI
import TonKit

struct EventView: View {
    @StateObject private var viewModel: EventViewModel
    @ObservedObject private var appViewModel: AppViewModel

    init(appViewModel: AppViewModel, tonKit: Kit) {
        _viewModel = StateObject(wrappedValue: EventViewModel(tonKit: tonKit))
        self.appViewModel = appViewModel
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.events, id: \.id) { event in
                    VStack {
                        info(title: "Id", value: event.id)
                        info(title: "Lt", value: "\(event.lt)")
                        info(title: "Timestamp", value: Date(timeIntervalSince1970: TimeInterval(event.timestamp)).formatted(date: .abbreviated, time: .standard))
                        info(title: "Scam", value: "\(event.isScam)")
                        info(title: "In Progress", value: "\(event.inProgress)")

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
