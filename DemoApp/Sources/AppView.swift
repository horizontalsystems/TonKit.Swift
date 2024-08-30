import SwiftUI

@main
struct AppView: App {
    @StateObject var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            if let tonKit = viewModel.tonKit {
                MainView(appViewModel: viewModel, tonKit: tonKit)
            } else {
                LoginView(appViewModel: viewModel)
            }
        }
    }
}
