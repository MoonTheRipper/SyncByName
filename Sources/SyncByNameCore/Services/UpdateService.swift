import Foundation

public enum UpdateServiceError: LocalizedError {
    case invalidResponse
    case unexpectedStatusCode(Int)
    case missingDownloadAsset
    case unableToCreateDownloadsDirectory

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The update service returned an invalid response."
        case let .unexpectedStatusCode(code):
            return "The update service returned status code \(code)."
        case .missingDownloadAsset:
            return "No suitable release asset was available for download."
        case .unableToCreateDownloadsDirectory:
            return "Sync by Name could not create the updates download directory."
        }
    }
}

public actor UpdateService {
    private let repository: GitHubRepository
    private let session: URLSession
    private let fileManager: FileManager
    private let decoder: JSONDecoder

    public init(
        repository: GitHubRepository = SyncByNameIdentity.repository,
        session: URLSession = .shared,
        fileManager: FileManager = .default
    ) {
        self.repository = repository
        self.session = session
        self.fileManager = fileManager

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func checkForUpdate(currentVersion: String) async throws -> AppUpdateInfo? {
        let release = try await latestRelease()
        let update = AppUpdateInfo(
            currentVersion: currentVersion,
            release: release,
            preferredAsset: preferredAsset(for: release)
        )

        return update.isNewerThanCurrentVersion ? update : nil
    }

    public func latestRelease() async throws -> AppRelease {
        var request = URLRequest(url: repository.latestReleaseAPIURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("SyncByName", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UpdateServiceError.invalidResponse
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            throw UpdateServiceError.unexpectedStatusCode(httpResponse.statusCode)
        }

        return try decoder.decode(AppRelease.self, from: data)
    }

    public func preferredAsset(for release: AppRelease) -> ReleaseAsset? {
        release.assets.max { assetScore(for: $0) < assetScore(for: $1) }
    }

    public func downloadPreferredAsset(for release: AppRelease) async throws -> URL {
        guard let asset = preferredAsset(for: release) else {
            throw UpdateServiceError.missingDownloadAsset
        }

        return try await download(asset: asset)
    }

    public func download(asset: ReleaseAsset) async throws -> URL {
        let directoryURL = try downloadsDirectory()
        let destinationURL = uniqueDestinationURL(for: asset.name, in: directoryURL)

        var request = URLRequest(url: asset.browserDownloadURL)
        request.setValue("SyncByName", forHTTPHeaderField: "User-Agent")

        let (temporaryURL, response) = try await session.download(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UpdateServiceError.invalidResponse
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            throw UpdateServiceError.unexpectedStatusCode(httpResponse.statusCode)
        }

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        try fileManager.moveItem(at: temporaryURL, to: destinationURL)
        return destinationURL
    }

    private func assetScore(for asset: ReleaseAsset) -> Int {
        let name = asset.name.lowercased()
        var score = 0

        switch asset.fileExtension {
        case "dmg":
            score += 120
        case "zip":
            score += 110
        case "pkg":
            score += 100
        default:
            break
        }

        if name.contains("macos") || name.contains("darwin") || name.contains("osx") {
            score += 35
        }
        if name.contains("universal") {
            score += 25
        }
        if name.contains("arm64") || name.contains("apple-silicon") {
            score += 20
        }
        if name.contains("intel") || name.contains("x86_64") {
            score -= 10
        }
        if name.contains("symbols") || name.contains("dsyms") || name.contains("source") {
            score -= 200
        }

        return score
    }

    private func downloadsDirectory() throws -> URL {
        let baseURL = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        let directoryURL = baseURL.appendingPathComponent("SyncByName Updates", isDirectory: true)

        if !fileManager.fileExists(atPath: directoryURL.path) {
            do {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            } catch {
                throw UpdateServiceError.unableToCreateDownloadsDirectory
            }
        }

        return directoryURL
    }

    private func uniqueDestinationURL(for fileName: String, in directory: URL) -> URL {
        let candidate = directory.appendingPathComponent(fileName)
        guard !fileManager.fileExists(atPath: candidate.path) else {
            let stem = candidate.deletingPathExtension().lastPathComponent
            let ext = candidate.pathExtension
            let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
            let amended = ext.isEmpty ? "\(stem)-\(timestamp)" : "\(stem)-\(timestamp).\(ext)"
            return directory.appendingPathComponent(amended)
        }

        return candidate
    }
}
