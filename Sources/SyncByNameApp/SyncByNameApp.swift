import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
        NSApp.applicationIconImage = BrandIconRenderer.makeImage(size: 512)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

@main
struct SyncByNameApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var controller = AppController()

    var body: some Scene {
        WindowGroup("Sync by Name", id: "main") {
            MainView(controller: controller)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 1080, height: 820)

        Window("Welcome to Sync by Name", id: "welcome") {
            WelcomeView(controller: controller)
        }
        .windowResizability(.contentSize)

        Window("Tutorials & Help", id: "tutorials") {
            TutorialsView(controller: controller)
        }
        .windowResizability(.contentSize)

        Window("Support & Feedback", id: "support") {
            SupportView(controller: controller)
        }
        .windowResizability(.contentSize)

        MenuBarExtra {
            MenuBarRootView(controller: controller)
        } label: {
            Image(systemName: "arrow.triangle.branch.circle.fill")
        }
    }
}
