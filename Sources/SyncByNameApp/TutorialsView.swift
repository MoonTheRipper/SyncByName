import SwiftUI

struct TutorialsView: View {
    @ObservedObject var controller: AppController
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 16) {
                    BrandIconView()
                        .frame(width: 72, height: 72)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tutorials & Help")
                            .font(.system(size: 28, weight: .bold))
                        Text("Quick ways to use Sync by Name safely and predictably.")
                            .foregroundStyle(.secondary)
                    }
                }

                TutorialCard(title: "Recovery Pass", symbol: "externaldrive.badge.plus") {
                    Text("Use this when you have multiple drives or folders and only want the filenames that have not shown up elsewhere yet.")
                    Text("Add the recovery source roots, then add every destination or archive folder you want to compare against.")
                }

                TutorialCard(title: "Media Filter Pass", symbol: "line.3.horizontal.decrease.circle.fill") {
                    Text("Use the extensions field to narrow scans to video, audio, or project types like `mp4, mov, mxf, wav`.")
                    Text("Leave the field empty if you want every regular file included.")
                }

                TutorialCard(title: "Safe Copy Rules", symbol: "checkmark.shield.fill") {
                    Text("The app compares filenames only. It does not treat path, date, or file size as the matching key.")
                    Text("Copying is non-destructive by default. Existing files in the output folder are skipped instead of replaced.")
                }

                HStack(spacing: 12) {
                    Button {
                        controller.resetWelcomeState()
                        openWindow(id: "welcome")
                    } label: {
                        Label("Show Welcome Again", systemImage: "sparkles.rectangle.stack")
                    }

                    Button {
                        openWindow(id: "support")
                    } label: {
                        Label("Support & Feedback", systemImage: "heart.text.square.fill")
                    }
                }
            }
            .padding(28)
        }
        .frame(minWidth: 760, minHeight: 560)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct TutorialCard<Content: View>: View {
    let title: String
    let symbol: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol)
                .font(.headline)
                .foregroundStyle(BrandPalette.ink)
            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(BrandPalette.parchment.opacity(0.58))
        )
    }
}
