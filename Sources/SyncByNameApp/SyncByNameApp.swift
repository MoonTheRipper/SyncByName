import SwiftUI

@main
struct SyncByNameApp: App {
    @StateObject private var controller = AppController()

    var body: some Scene {
        WindowGroup("Sync by Name") {
            MainView(controller: controller)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 1080, height: 820)
    }
}
