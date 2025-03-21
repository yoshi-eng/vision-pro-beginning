import SwiftUI

// MARK: - App Entry Point
@main
struct SpatialPlayerApp: App {
    @StateObject private var viewModel = PlayerViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
        
        ImmersiveSpace(id: "PlayerSpace") {
            ImmersiveView()
                .environmentObject(viewModel)
        }
        .immersionStyle(selection: .constant(.full), in: .full)
    }
}
