import AppKit
import SwiftUI

struct MenuBarRootView: View {
    @ObservedObject var controller: AppController
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Open Sync by Name") {
            controller.activateApp()
            openWindow(id: "main")
        }

        Button("Welcome Window") {
            controller.activateApp()
            controller.markWelcomeSeen()
            openWindow(id: "welcome")
        }

        Button("Tutorials & Help") {
            controller.activateApp()
            openWindow(id: "tutorials")
        }

        Button("Support & Feedback") {
            controller.activateApp()
            openWindow(id: "support")
        }

        Button(controller.isDownloadingUpdate ? "Downloading Latest Release…" : "Download Latest Release") {
            Task {
                await controller.downloadLatestRelease()
            }
        }
        .disabled(controller.isDownloadingUpdate)

        Button(controller.isCheckingForUpdates ? "Checking for Updates…" : "Check for Updates") {
            Task {
                await controller.checkForUpdates(manuallyInitiated: true)
            }
        }

        Button("Open Update Center") {
            controller.activateApp()
            openWindow(id: "updates")
        }

        Divider()

        Button("Donate on Ko-fi") {
            controller.openSupportPage()
        }

        Button("Send Feedback on GitHub") {
            controller.openFeedbackPage()
        }

        Divider()

        Button("Hide to Top Bar") {
            controller.hideToTopBar()
        }

        Button("Quit Sync by Name") {
            controller.quitApp()
        }

        Divider()

        Text(controller.statusMessage)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(3)
    }
}
