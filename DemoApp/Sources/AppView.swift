import SwiftUI

@main
struct AppView: App {
    @StateObject var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            if viewModel.tonKit != nil {
                MainView(appViewModel: viewModel)
            } else {
                LoginView(appViewModel: viewModel)
            }
        }
    }
}
