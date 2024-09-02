import SwiftUI
import TonKit

struct MainView: View {
    @ObservedObject private var appViewModel: AppViewModel
    private let tonKit: Kit

    init(appViewModel: AppViewModel, tonKit: Kit) {
        self.appViewModel = appViewModel
        self.tonKit = tonKit
    }

    var body: some View {
        TabView {
            BalanceView(appViewModel: appViewModel, tonKit: tonKit)
                .tabItem {
                    Label("Balance", systemImage: "creditcard.circle")
                }

            EventView(appViewModel: appViewModel, tonKit: tonKit)
                .tabItem {
                    Label("Transactions", systemImage: "list.bullet.circle")
                }

            if !tonKit.watchOnly {
                VStack {
                    Text("Send")
                    Spacer()
                }
                .tabItem {
                    Label("Send", systemImage: "paperplane.circle")
                }

                VStack {
                    Text("Jetton Send")
                    Spacer()
                }
                .tabItem {
                    Label("Jetton Send", systemImage: "paperplane.circle")
                }

                ReceiveView(tonKit: tonKit)
                    .tabItem {
                        Label("Receive", systemImage: "tray.circle")
                    }
            }
        }
    }
}
