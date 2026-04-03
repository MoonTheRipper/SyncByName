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
    @StateObject private var controller: AppController

    init() {
        let controller = AppController()
        _controller = StateObject(wrappedValue: controller)
        controller.start()
    }

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

        Window("Updates", id: "updates") {
            UpdateCenterView(controller: controller)
        }
        .windowResizability(.contentSize)

        MenuBarExtra {
            MenuBarRootView(controller: controller)
        } label: {
            MenuBarIconView(hasAvailableUpdate: controller.availableUpdate != nil)
        }
    }
}

private struct MenuBarIconView: View {
    let hasAvailableUpdate: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(nsImage: BrandIconRenderer.makeImage(size: 18))

            if hasAvailableUpdate {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 8, weight: .bold))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, BrandPalette.skyGlow)
                    .background(
                        Circle()
                            .fill(BrandPalette.ink.opacity(0.92))
                            .frame(width: 10, height: 10)
                    )
                    .offset(x: 3, y: -3)
            }
        }
    }
}
