import SwiftUI

@main
struct SplitWiseApp: App {
    @StateObject private var dataManager = DataManager.shared

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(dataManager)
        }
    }
}
