import Foundation

struct AppSettingsSnapshot: Codable {
    var sourcePaths: [String] = []
    var comparisonPaths: [String] = []
    var outputPath: String?
    var allowedExtensionsText = "mp4, mov, mxf"
    var caseSensitiveFilenames = false
    var ignoreHiddenFiles = true
    var preserveSourceFolders = true
    var hasSeenWelcome = false
    var automaticallyCheckForUpdates = true
    var lastUpdateCheckAt: Date?
}

@MainActor
final class AppSettingsStore {
    private let userDefaults: UserDefaults
    private let key = "SyncByName.AppSettings"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> AppSettingsSnapshot {
        guard let data = userDefaults.data(forKey: key) else {
            return AppSettingsSnapshot()
        }

        return (try? decoder.decode(AppSettingsSnapshot.self, from: data)) ?? AppSettingsSnapshot()
    }

    func save(_ snapshot: AppSettingsSnapshot) {
        guard let data = try? encoder.encode(snapshot) else {
            return
        }
        userDefaults.set(data, forKey: key)
    }
}
