import Foundation

public struct GitHubRepository: Hashable, Sendable {
    public let owner: String
    public let name: String

    public init(owner: String, name: String) {
        self.owner = owner
        self.name = name
    }

    public var repositoryURL: URL {
        URL(string: "https://github.com/\(owner)/\(name)")!
    }

    public var latestReleaseAPIURL: URL {
        URL(string: "https://api.github.com/repos/\(owner)/\(name)/releases/latest")!
    }
}

public enum SyncByNameIdentity {
    public static let appName = "Sync by Name"
    public static let bundleName = "SyncByName"
    public static let bundleIdentifier = "com.moontheripper.SyncByName"
    public static let repository = GitHubRepository(owner: "MoonTheRipper", name: "SyncByName")
    public static let supportURL = URL(string: "https://ko-fi.com/moontheripper")!
    public static let defaultVersion = "0.1.0"
}

public enum AppRuntimeInfo {
    public static func currentVersion(bundle: Bundle = .main) -> String {
        if let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           !version.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return version
        }

        return SyncByNameIdentity.defaultVersion
    }
}
