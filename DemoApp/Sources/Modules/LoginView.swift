import SwiftUI
import TonSwift

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @ObservedObject private var appViewModel: AppViewModel

    @State private var mnemonic = Configuration.shared.defaultsWords
    @State private var watchAddress = Configuration.shared.defaultsWatchAddress
    @State private var alertText: String?

    init(appViewModel: AppViewModel) {
        self.appViewModel = appViewModel
    }

    var body: some View {
        TabView {
            VStack {
                TextField("Mnemonic", text: $mnemonic, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(5, reservesSpace: true)
                    .padding()

                VStack(spacing: 24) {
                    Button("Generate") {
                        let words = Mnemonic.mnemonicNew()
                        mnemonic = words.joined(separator: " ")
                    }

                    Button("Login") {
                        let words = mnemonic.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }

                        do {
                            try appViewModel.login(words: words)
                        } catch {
                            alertText = "\(error)"
                        }
                    }
                }

                Spacer()
            }
            .tabItem {
                Label("Mnemonic", systemImage: "text.word.spacing")
            }

            VStack {
                TextField("Watch Address", text: $watchAddress, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3, reservesSpace: true)
                    .padding()

                Button("Watch") {
                    do {
                        try appViewModel.watch(address: watchAddress)
                    } catch {
                        alertText = "\(error)"
                    }
                }

                Spacer()
            }
            .tabItem {
                Label("Watch", systemImage: "eyes")
            }
        }
        .alert(item: $alertText) { text in
            Alert(title: Text("Error"), message: Text(text), dismissButton: .cancel(Text("Got It")))
        }
    }
}
