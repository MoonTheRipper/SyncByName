import SwiftUI
import SyncByNameCore

struct WelcomeView: View {
    @ObservedObject var controller: AppController
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    BrandPalette.obsidian,
                    BrandPalette.midnight,
                    BrandPalette.deepOcean
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(BrandPalette.skyGlow.opacity(0.22))
                .frame(width: 280, height: 280)
                .blur(radius: 18)
                .offset(x: 250, y: -160)

            Circle()
                .fill(BrandPalette.blueMist.opacity(0.18))
                .frame(width: 240, height: 240)
                .blur(radius: 14)
                .offset(x: -250, y: 180)

            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top, spacing: 18) {
                    BrandIconView()
                        .frame(width: 92, height: 92)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: Color.black.opacity(0.24), radius: 18, x: 0, y: 10)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Welcome to Sync by Name")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(BrandPalette.cloud)
                        Text("Preview-first filename-only comparison and copy for folders and drives.")
                            .foregroundStyle(BrandPalette.blueMist)
                        Text("The app only compares filenames. It does not delete, move, or overwrite by default.")
                            .foregroundStyle(BrandPalette.blueMist.opacity(0.94))
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    WelcomeStep(symbol: "folder.badge.plus", title: "1. Add source folders", description: "Choose the folders or drives you want to scan for candidate files.")
                    WelcomeStep(symbol: "folder.badge.questionmark", title: "2. Add comparison folders", description: "Pick the locations that represent what you already have.")
                    WelcomeStep(symbol: "doc.text.magnifyingglass", title: "3. Preview missing filenames", description: "Run the scan to see which filenames appear in sources but nowhere in the comparison set.")
                    WelcomeStep(symbol: "arrow.down.doc.fill", title: "4. Copy only what is missing", description: "Choose an output folder and copy the previewed files into it.")
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white.opacity(0.09))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(BrandPalette.blueMist.opacity(0.18), lineWidth: 1)
                        )
                )

                HStack(spacing: 12) {
                    Button {
                        controller.markWelcomeSeen()
                        dismiss()
                    } label: {
                        Label("Start Scanning", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(BrandPalette.skyGlow)

                    Button {
                        controller.markWelcomeSeen()
                        openWindow(id: "tutorials")
                    } label: {
                        Label("Open Tutorial", systemImage: "list.bullet.rectangle.portrait")
                    }
                    .buttonStyle(.bordered)
                    .tint(BrandPalette.blueMist)

                    Button {
                        controller.openSupportPage()
                    } label: {
                        Label("Donate on Ko-fi", systemImage: "cup.and.saucer.fill")
                    }
                    .buttonStyle(.bordered)
                    .tint(BrandPalette.blueMist)
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .stroke(BrandPalette.blueMist.opacity(0.16), lineWidth: 1)
                    )
            )
            .padding(22)
        }
        .frame(minWidth: 720, minHeight: 520)
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
                .foregroundStyle(BrandPalette.skyGlow)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(BrandPalette.cloud)
                Text(description)
                    .foregroundStyle(BrandPalette.blueMist)
            }
        }
    }
}
