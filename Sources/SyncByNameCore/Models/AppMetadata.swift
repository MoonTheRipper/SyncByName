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

    public var issuesURL: URL {
        repositoryURL.appending(path: "issues")
    }

    public var sourceArchiveURL: URL {
        repositoryURL.appending(path: "archive/refs/heads/main.zip")
    }
}

public enum SyncByNameIdentity {
    public static let appName = "Sync by Name"
    public static let bundleName = "SyncByName"
    public static let bundleIdentifier = "com.moontheripper.SyncByName"
    public static let repository = GitHubRepository(owner: "MoonTheRipper", name: "SyncByName")
    public static let supportURL = URL(string: "https://ko-fi.com/I2I61WTJ6V")!
    public static let defaultVersion = "0.2.1"
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
