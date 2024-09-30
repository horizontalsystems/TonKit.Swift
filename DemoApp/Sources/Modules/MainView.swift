import SwiftUI
import TonKit

struct MainView: View {
    @ObservedObject private var appViewModel: AppViewModel

    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
    }

    var body: some View {
        TabView {
            BalanceView(appViewModel: appViewModel)
                .tabItem {
                    Label("Balance", systemImage: "creditcard.circle")
                }

            EventView(appViewModel: appViewModel)
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet.circle")
                }

            if Singleton.keyPair != nil {
                SendView()
                    .tabItem {
                        Label("Send", systemImage: "paperplane.circle")
                    }

                ReceiveView()
                    .tabItem {
                        Label("Receive", systemImage: "tray.circle")
                    }
            }
        }
    }
}
