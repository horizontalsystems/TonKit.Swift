import SwiftUI
import TonKit

struct BalanceView: View {
    @StateObject private var viewModel = BalanceViewModel()
    @ObservedObject private var appViewModel: AppViewModel

    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                info(title: "Address", value: viewModel.address)
                info(title: "Sync State", value: viewModel.syncState.description)
                info(title: "Jetton Sync State", value: viewModel.jettonSyncState.description)
                info(title: "Event Sync State", value: viewModel.eventSyncState.description)
                info(title: "Balance", value: viewModel.account?.balance.tonDecimalValue.map { "\($0) TON" } ?? "n/a")
                info(title: "Status", value: viewModel.account.map { "\($0.status.rawValue)" } ?? "n/a")

                Divider()

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.jettonBalanceMap.map { $0.value }.sorted { $0.jetton.name < $1.jetton.name }, id: \.jetton.address) { balance in
                            info(title: balance.jetton.name, value: balance.balance.decimalValue(decimals: balance.jetton.decimals).map { "\($0) \(balance.jetton.symbol)" } ?? "n/a")
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
            .padding()
            .navigationTitle("Balance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        appViewModel.logout()
                    } label: {
                        Image(systemName: "person.slash")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.refresh()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }

    @ViewBuilder private func info(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text("\(title):")
                .font(.system(size: 16))

            Spacer()

            Text(value)
                .font(.system(size: 14))
                .multilineTextAlignment(.trailing)
        }
    }
}
