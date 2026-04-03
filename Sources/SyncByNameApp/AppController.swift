import AppKit
import Foundation
import SyncByNameCore

@MainActor
final class AppController: ObservableObject {
    @Published var sourceRoots: [URL]
    @Published var comparisonRoots: [URL]
    @Published var outputRoot: URL?
    @Published var allowedExtensionsText: String
    @Published var caseSensitiveFilenames: Bool
    @Published var ignoreHiddenFiles: Bool
    @Published var preserveSourceFolders: Bool
    @Published var automaticallyCheckForUpdates: Bool
    @Published private(set) var plan: SyncPlan?
    @Published private(set) var statusMessage = "Select folders to start a filename-only scan."
    @Published private(set) var isBusy = false
    @Published private(set) var shouldPresentInitialWelcome: Bool
    @Published private(set) var isCheckingForUpdates = false
    @Published private(set) var isDownloadingUpdate = false
    @Published private(set) var availableUpdate: AppUpdateInfo?
    @Published private(set) var lastDownloadedUpdateURL: URL?

    private let settingsStore: AppSettingsStore
    private let updateService: UpdateService
    private var hasSeenWelcome: Bool
    private var lastUpdateCheckAt: Date?
    private let currentVersion = AppRuntimeInfo.currentVersion()
    private var started = false

    init(
        settingsStore: AppSettingsStore = AppSettingsStore(),
        updateService: UpdateService = UpdateService()
    ) {
        self.settingsStore = settingsStore
        self.updateService = updateService
        let snapshot = settingsStore.load()
        sourceRoots = snapshot.sourcePaths.map(URL.init(fileURLWithPath:))
        comparisonRoots = snapshot.comparisonPaths.map(URL.init(fileURLWithPath:))
        outputRoot = snapshot.outputPath.map(URL.init(fileURLWithPath:))
        allowedExtensionsText = snapshot.allowedExtensionsText
        caseSensitiveFilenames = snapshot.caseSensitiveFilenames
        ignoreHiddenFiles = snapshot.ignoreHiddenFiles
        preserveSourceFolders = snapshot.preserveSourceFolders
        hasSeenWelcome = snapshot.hasSeenWelcome
        automaticallyCheckForUpdates = snapshot.automaticallyCheckForUpdates
        lastUpdateCheckAt = snapshot.lastUpdateCheckAt
        shouldPresentInitialWelcome = !snapshot.hasSeenWelcome
    }

    var currentVersionDisplay: String {
        currentVersion
    }

    var lastUpdateCheckDescription: String {
        guard let lastUpdateCheckAt else {
            return "Not checked yet"
        }

        return lastUpdateCheckAt.formatted(date: .abbreviated, time: .shortened)
    }

    func start() {
        guard !started else {
            return
        }
        started = true

        if automaticallyCheckForUpdates {
            Task {
                await checkForUpdates(manuallyInitiated: false)
            }
        }
    }

    func addSourceRoots() {
        let urls = pickFolders()
        guard !urls.isEmpty else {
            return
        }
        sourceRoots = merge(existing: sourceRoots, with: urls)
        persist()
    }

    func addComparisonRoots() {
        let urls = pickFolders()
        guard !urls.isEmpty else {
            return
        }
        comparisonRoots = merge(existing: comparisonRoots, with: urls)
        persist()
    }

    func chooseOutputRoot() {
        guard let url = pickFolders(allowsMultipleSelection: false).first else {
            return
        }
        outputRoot = url
        persist()
    }

    func removeSourceRoot(_ url: URL) {
        sourceRoots.removeAll { $0.path == url.path }
        persist()
    }

    func removeComparisonRoot(_ url: URL) {
        comparisonRoots.removeAll { $0.path == url.path }
        persist()
    }

    func clearPlan() {
        plan = nil
        statusMessage = "Scan cleared."
    }

    func scan() async {
        guard !sourceRoots.isEmpty else {
            statusMessage = "Add at least one source folder."
            return
        }

        guard !comparisonRoots.isEmpty else {
            statusMessage = "Add at least one comparison folder."
            return
        }

        isBusy = true
        defer { isBusy = false }

        let configuration = ScanConfiguration(
            sourceRoots: sourceRoots,
            comparisonRoots: comparisonRoots,
            allowedExtensions: parsedExtensions(),
            caseSensitiveFilenames: caseSensitiveFilenames,
            ignoreHiddenFiles: ignoreHiddenFiles
        )

        do {
            let plan = try await Task.detached(priority: .userInitiated) {
                try FilenameSyncPlanner.buildPlan(configuration: configuration)
            }.value

            self.plan = plan
            if plan.items.isEmpty {
                statusMessage = "No missing filenames found."
            } else {
                statusMessage = "Found \(plan.summary.missingFileCount) missing files by filename."
            }
        } catch {
            statusMessage = "Scan failed: \(error.localizedDescription)"
        }
    }

    func copyMissingFiles() async {
        guard let plan else {
            statusMessage = "Run a scan before copying."
            return
        }

        guard let outputRoot else {
            statusMessage = "Choose an output folder first."
            return
        }

        isBusy = true
        defer { isBusy = false }

        let configuration = CopyConfiguration(
            outputRoot: outputRoot,
            preserveSourceFolders: preserveSourceFolders
        )

        do {
            let result = try await Task.detached(priority: .userInitiated) {
                try CopyEngine.copy(plan: plan, configuration: configuration)
            }.value

            statusMessage = "Copied \(result.copiedDestinations.count) files. Skipped \(result.skippedItems.count). Failed \(result.failures.count)."
        } catch {
            statusMessage = "Copy failed: \(error.localizedDescription)"
        }
    }

    func updateAllowedExtensionsText(_ value: String) {
        allowedExtensionsText = value
        persist()
    }

    func updatePreserveSourceFolders(_ value: Bool) {
        preserveSourceFolders = value
        persist()
    }

    func updateCaseSensitiveFilenames(_ value: Bool) {
        caseSensitiveFilenames = value
        persist()
    }

    func updateIgnoreHiddenFiles(_ value: Bool) {
        ignoreHiddenFiles = value
        persist()
    }

    func updateAutomaticallyCheckForUpdates(_ value: Bool) {
        automaticallyCheckForUpdates = value
        persist()
    }

    func consumeInitialWelcomeRequest() -> Bool {
        guard shouldPresentInitialWelcome else {
            return false
        }

        shouldPresentInitialWelcome = false
        return true
    }

    func markWelcomeSeen() {
        guard !hasSeenWelcome else {
            return
        }

        hasSeenWelcome = true
        persist()
    }

    func resetWelcomeState() {
        hasSeenWelcome = false
        shouldPresentInitialWelcome = true
        persist()
    }

    func openSupportPage() {
        NSWorkspace.shared.open(SyncByNameIdentity.supportURL)
    }

    func openRepository() {
        NSWorkspace.shared.open(SyncByNameIdentity.repository.repositoryURL)
    }

    func openFeedbackPage() {
        NSWorkspace.shared.open(SyncByNameIdentity.repository.issuesURL)
    }

    func openReleasesPage() {
        NSWorkspace.shared.open(SyncByNameIdentity.repository.latestReleasePageURL)
    }

    func openAvailableReleaseNotes() {
        if let availableUpdate {
            NSWorkspace.shared.open(availableUpdate.release.htmlURL)
        } else {
            openReleasesPage()
        }
    }

    func checkForUpdates(manuallyInitiated: Bool) async {
        guard !isCheckingForUpdates else {
            return
        }

        isCheckingForUpdates = true
        defer { isCheckingForUpdates = false }

        do {
            let update = try await updateService.checkForUpdate(currentVersion: currentVersion)
            availableUpdate = update
            lastUpdateCheckAt = Date()
            persist()

            if let update {
                statusMessage = "Update \(update.release.tagName) is available."
            } else if manuallyInitiated {
                statusMessage = "Sync by Name is up to date."
            }
        } catch {
            if manuallyInitiated {
                statusMessage = "Update check failed: \(error.localizedDescription)"
            }
        }
    }

    func downloadLatestRelease() async {
        guard !isDownloadingUpdate else {
            return
        }

        isDownloadingUpdate = true
        defer { isDownloadingUpdate = false }

        do {
            let release: AppRelease
            if let availableUpdate {
                release = availableUpdate.release
            } else {
                release = try await updateService.latestRelease()
                let preferredAsset = await updateService.preferredAsset(for: release)
                let latestInfo = AppUpdateInfo(
                    currentVersion: currentVersion,
                    release: release,
                    preferredAsset: preferredAsset
                )
                availableUpdate = latestInfo.isNewerThanCurrentVersion ? latestInfo : nil
                lastUpdateCheckAt = Date()
                persist()
            }

            let downloadedURL = try await updateService.downloadPreferredAsset(for: release)
            lastDownloadedUpdateURL = downloadedURL
            statusMessage = "Downloaded \(downloadedURL.lastPathComponent) from GitHub Releases."

            NSWorkspace.shared.activateFileViewerSelecting([downloadedURL])
            if downloadedURL.pathExtension.lowercased() == "dmg" {
                NSWorkspace.shared.open(downloadedURL)
            }
        } catch {
            statusMessage = "Update download failed: \(error.localizedDescription)"
        }
    }

    func hideToTopBar() {
        NSApp.hide(nil)
    }

    func activateApp() {
        NSApp.activate(ignoringOtherApps: true)
    }

    func quitApp() {
        NSApp.terminate(nil)
    }

    private func pickFolders(allowsMultipleSelection: Bool = true) -> [URL] {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = allowsMultipleSelection
        panel.canCreateDirectories = true

        return panel.runModal() == .OK ? panel.urls : []
    }

    private func parsedExtensions() -> Set<String> {
        Set(
            allowedExtensionsText
                .split(separator: ",")
                .map {
                    $0.trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: ".", with: "")
                        .lowercased()
                }
                .filter { !$0.isEmpty }
        )
    }

    private func merge(existing: [URL], with newURLs: [URL]) -> [URL] {
        let byPath = Dictionary(
            uniqueKeysWithValues: (existing + newURLs).map { ($0.standardizedFileURL.path, $0.standardizedFileURL) }
        )
        return byPath.values.sorted {
            $0.path.localizedCaseInsensitiveCompare($1.path) == .orderedAscending
        }
    }

    private func persist() {
        settingsStore.save(
            AppSettingsSnapshot(
                sourcePaths: sourceRoots.map(\.path),
                comparisonPaths: comparisonRoots.map(\.path),
                outputPath: outputRoot?.path,
                allowedExtensionsText: allowedExtensionsText,
                caseSensitiveFilenames: caseSensitiveFilenames,
                ignoreHiddenFiles: ignoreHiddenFiles,
                preserveSourceFolders: preserveSourceFolders,
                hasSeenWelcome: hasSeenWelcome,
                automaticallyCheckForUpdates: automaticallyCheckForUpdates,
                lastUpdateCheckAt: lastUpdateCheckAt
            )
        )
    }
}
