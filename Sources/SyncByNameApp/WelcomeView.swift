import SwiftUI
import SyncByNameCore

struct WelcomeView: View {
    @ObservedObject var controller: AppController
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .top, spacing: 18) {
                BrandIconView()
                    .frame(width: 92, height: 92)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Welcome to Sync by Name")
                        .font(.system(size: 30, weight: .bold))
                    Text("Preview-first filename-only comparison and copy for folders and drives.")
                        .foregroundStyle(.secondary)
                    Text("The app only compares filenames. It does not delete, move, or overwrite by default.")
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                WelcomeStep(symbol: "folder.badge.plus", title: "1. Add source folders", description: "Choose the folders or drives you want to scan for candidate files.")
                WelcomeStep(symbol: "folder.badge.questionmark", title: "2. Add comparison folders", description: "Pick the locations that represent what you already have.")
                WelcomeStep(symbol: "doc.text.magnifyingglass", title: "3. Preview missing filenames", description: "Run the scan to see which filenames appear in sources but nowhere in the comparison set.")
                WelcomeStep(symbol: "arrow.down.doc.fill", title: "4. Copy only what is missing", description: "Choose an output folder and copy the previewed files into it.")
            }

            HStack(spacing: 12) {
                Button {
                    controller.markWelcomeSeen()
                    dismiss()
                } label: {
                    Label("Start Scanning", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    controller.markWelcomeSeen()
                    openWindow(id: "tutorials")
                } label: {
                    Label("Open Tutorial", systemImage: "list.bullet.rectangle.portrait")
                }
                .buttonStyle(.bordered)

                Button {
                    controller.openSupportPage()
                } label: {
                    Label("Donate on Ko-fi", systemImage: "cup.and.saucer.fill")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(28)
        .frame(minWidth: 720, minHeight: 520)
        .background(
            LinearGradient(
                colors: [
                    BrandPalette.parchment.opacity(0.92),
                    BrandPalette.parchment.opacity(0.72)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onAppear {
            controller.markWelcomeSeen()
        }
    }
}

private struct WelcomeStep: View {
    let symbol: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(BrandPalette.deepOcean)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
