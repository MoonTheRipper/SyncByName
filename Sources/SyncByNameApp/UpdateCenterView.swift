import SwiftUI

struct UpdateCenterView: View {
    @ObservedObject var controller: AppController

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                statusCard
                releaseCard
            }
            .padding(24)
        }
        .frame(minWidth: 680, minHeight: 520)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Updates", systemImage: "arrow.down.circle.fill")
                .font(.system(size: 28, weight: .semibold))
            Text("Sync by Name checks GitHub releases for new versions and can download the latest macOS release asset directly from the app.")
                .foregroundStyle(.secondary)
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Build")
                .font(.headline)
            Text("Version \(controller.currentVersionDisplay)")
            Text("Last checked: \(controller.lastUpdateCheckDescription)")
                .foregroundStyle(.secondary)

            Toggle(
                "Automatically check for updates on startup",
                isOn: Binding(
                    get: { controller.automaticallyCheckForUpdates },
                    set: { controller.updateAutomaticallyCheckForUpdates($0) }
                )
            )

            HStack(spacing: 12) {
                Button(controller.isCheckingForUpdates ? "Checking…" : "Check Now") {
                    Task {
                        await controller.checkForUpdates(manuallyInitiated: true)
                    }
                }
                .disabled(controller.isCheckingForUpdates)

                Button("Open Releases Page") {
                    controller.openReleasesPage()
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(BrandPalette.blueMist.opacity(0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(BrandPalette.deepOcean.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private var releaseCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let update = controller.availableUpdate {
                Text("Update Available")
                    .font(.headline)

                Text("\(update.release.displayName) is ready to download.")
                    .font(.title3)

                if let publishedAt = update.release.publishedAt {
                    Text("Published \(publishedAt.formatted(date: .abbreviated, time: .omitted))")
                        .foregroundStyle(.secondary)
                }

                if !update.release.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(update.release.body)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                if let asset = update.preferredAsset {
                    Text("Preferred asset: \(asset.name)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Button(controller.isDownloadingUpdate ? "Downloading…" : "Download Latest Release") {
                        Task {
                            await controller.downloadLatestRelease()
                        }
                    }
                    .disabled(controller.isDownloadingUpdate)

                    Button("Release Notes") {
                        controller.openAvailableReleaseNotes()
                    }
                }

                if let downloadedURL = controller.lastDownloadedUpdateURL {
                    Text("Latest downloaded file: \(downloadedURL.lastPathComponent)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            } else {
                Text("No Newer Update Available")
                    .font(.headline)
                Text("Sync by Name is already current, but you can still pull the latest GitHub release package from here.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    Button(controller.isDownloadingUpdate ? "Downloading…" : "Download Latest Release") {
                        Task {
                            await controller.downloadLatestRelease()
                        }
                    }
                    .disabled(controller.isDownloadingUpdate)

                    Button("Open Releases Page") {
                        controller.openReleasesPage()
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(BrandPalette.blueMist.opacity(0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(BrandPalette.deepOcean.opacity(0.12), lineWidth: 1)
                )
        )
    }
}
