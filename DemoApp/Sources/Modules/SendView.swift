import SwiftUI
import TonKit
import UIKit

struct SendView: View {
    @StateObject private var viewModel: SendViewModel

    init(tonKit: Kit) {
        _viewModel = StateObject(wrappedValue: SendViewModel(tonKit: tonKit))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Address", text: $viewModel.address, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3)

                TextField("Amount", text: $viewModel.amount, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1)

                TextField("Comment", text: $viewModel.comment, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3)

                HStack {
                    Text("Estimated Fee:").font(.system(size: 14))
                    Spacer()
                    Text(viewModel.estimatedFee ?? "n/a").font(.system(size: 14))
                }

                Button("Send") {
                    viewModel.send()
                }

                Spacer()
            }
            .padding()
            .alert(item: $viewModel.errorAlertText) { text in
                Alert(title: Text("Error"), message: Text(text), dismissButton: .cancel(Text("Got It")))
            }
            .alert(item: $viewModel.sentAlertText) { text in
                Alert(title: Text("Sent"), message: Text(text), dismissButton: .cancel(Text("Got It")))
            }
            .navigationTitle("Send TON")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
