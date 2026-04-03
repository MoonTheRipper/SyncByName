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
    @Published private(set) var plan: SyncPlan?
    @Published private(set) var statusMessage = "Select folders to start a filename-only scan."
    @Published private(set) var isBusy = false
    @Published private(set) var shouldPresentInitialWelcome: Bool

    private let settingsStore: AppSettingsStore
    private var hasSeenWelcome: Bool

    init(settingsStore: AppSettingsStore = AppSettingsStore()) {
        self.settingsStore = settingsStore
        let snapshot = settingsStore.load()
        sourceRoots = snapshot.sourcePaths.map(URL.init(fileURLWithPath:))
        comparisonRoots = snapshot.comparisonPaths.map(URL.init(fileURLWithPath:))
        outputRoot = snapshot.outputPath.map(URL.init(fileURLWithPath:))
        allowedExtensionsText = snapshot.allowedExtensionsText
        caseSensitiveFilenames = snapshot.caseSensitiveFilenames
        ignoreHiddenFiles = snapshot.ignoreHiddenFiles
        preserveSourceFolders = snapshot.preserveSourceFolders
        hasSeenWelcome = snapshot.hasSeenWelcome
        shouldPresentInitialWelcome = !snapshot.hasSeenWelcome
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
                hasSeenWelcome: hasSeenWelcome
            )
        )
    }
}
