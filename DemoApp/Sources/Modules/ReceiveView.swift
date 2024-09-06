import SwiftUI
import TonKit
import UIKit

struct ReceiveView: View {
    @StateObject private var viewModel = ReceiveViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(viewModel.address)
                    .multilineTextAlignment(.center)

                Button("Copy") {
                    UIPasteboard.general.string = viewModel.address
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Receive")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
