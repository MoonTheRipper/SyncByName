import Foundation

public struct AppVersion: Comparable, Hashable, Sendable, CustomStringConvertible {
    public let rawValue: String
    public let numericComponents: [Int]

    public init(_ rawValue: String) {
        self.rawValue = rawValue
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let numericPrefix = trimmed.drop { !$0.isNumber }
        let tokens = numericPrefix.split { !$0.isNumber }
        numericComponents = tokens.compactMap { Int($0) }
    }

    public var description: String {
        rawValue
    }

    public static func == (lhs: AppVersion, rhs: AppVersion) -> Bool {
        lhs.normalizedNumericComponents == rhs.normalizedNumericComponents
    }

    public static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        let count = max(lhs.numericComponents.count, rhs.numericComponents.count)
        for index in 0..<count {
            let lhsValue = lhs.numericComponents[safe: index] ?? 0
            let rhsValue = rhs.numericComponents[safe: index] ?? 0
            if lhsValue != rhsValue {
                return lhsValue < rhsValue
            }
        }

        return false
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(normalizedNumericComponents)
    }

    private var normalizedNumericComponents: [Int] {
        var components = numericComponents

        while components.count > 1, components.last == 0 {
            components.removeLast()
        }

        return components
    }
}

public struct ReleaseAsset: Codable, Hashable, Identifiable, Sendable {
    public let id: Int
    public let name: String
    public let browserDownloadURL: URL
    public let contentType: String?
    public let size: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case browserDownloadURL = "browser_download_url"
        case contentType = "content_type"
        case size
    }

    public var fileExtension: String {
        URL(fileURLWithPath: name).pathExtension.lowercased()
    }
}

public struct AppRelease: Codable, Hashable, Identifiable, Sendable {
    public let id: Int
    public let tagName: String
    public let name: String?
    public let body: String
    public let htmlURL: URL
    public let draft: Bool
    public let prerelease: Bool
    public let publishedAt: Date?
    public let assets: [ReleaseAsset]

    enum CodingKeys: String, CodingKey {
        case id
        case tagName = "tag_name"
        case name
        case body
        case htmlURL = "html_url"
        case draft
        case prerelease
        case publishedAt = "published_at"
        case assets
    }

    public var displayName: String {
        let preferred = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        return preferred?.isEmpty == false ? preferred! : tagName
    }

    public var version: AppVersion {
        AppVersion(tagName)
    }
}

public struct AppUpdateInfo: Hashable, Sendable {
    public let currentVersion: String
    public let release: AppRelease
    public let preferredAsset: ReleaseAsset?

    public init(
        currentVersion: String,
        release: AppRelease,
        preferredAsset: ReleaseAsset?
    ) {
        self.currentVersion = currentVersion
        self.release = release
        self.preferredAsset = preferredAsset
    }

    public var currentAppVersion: AppVersion {
        AppVersion(currentVersion)
    }

    public var releaseVersion: AppVersion {
        release.version
    }

    public var isNewerThanCurrentVersion: Bool {
        releaseVersion > currentAppVersion
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else {
            return nil
        }

        return self[index]
    }
}
