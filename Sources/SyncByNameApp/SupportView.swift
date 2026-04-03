import SwiftUI
import SyncByNameCore

struct SupportView: View {
    @ObservedObject var controller: AppController

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 16) {
                BrandIconView()
                    .frame(width: 72, height: 72)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Support & Feedback")
                        .font(.system(size: 28, weight: .bold))
                    Text("Support development, report issues, and reopen learning resources from here.")
                        .foregroundStyle(.secondary)
                }
            }

            SupportCard(title: "Support Development", symbol: "cup.and.saucer.fill") {
                Text("If Sync by Name saves you time during recovery or collection work, you can support future releases on Ko-fi.")
                Button {
                    controller.openSupportPage()
                } label: {
                    Label("Donate on Ko-fi", systemImage: "cup.and.saucer.fill")
                }
                .buttonStyle(.borderedProminent)
            }

            SupportCard(title: "Feedback", symbol: "bubble.left.and.exclamationmark.bubble.right.fill") {
                Text("Use GitHub issues for bug reports, feature requests, and workflow feedback.")
                HStack(spacing: 12) {
                    Button("Open Issues") {
                        controller.openFeedbackPage()
                    }
                    .buttonStyle(.bordered)

                    Button("Open Repository") {
                        controller.openRepository()
                    }
                    .buttonStyle(.bordered)
                }
            }

            SupportCard(title: "Version", symbol: "shippingbox.fill") {
                Text("Current release: \(AppRuntimeInfo.currentVersion())")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(28)
        .frame(minWidth: 720, minHeight: 520)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct SupportCard<Content: View>: View {
    let title: String
    let symbol: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol)
                .font(.headline)
            content()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(BrandPalette.parchment.opacity(0.55))
        )
    }
}
