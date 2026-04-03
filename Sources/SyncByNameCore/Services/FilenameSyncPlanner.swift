import Foundation

public enum FilenameSyncPlanner {
    public static func buildPlan(configuration: ScanConfiguration) throws -> SyncPlan {
        let normalizedExtensions = normalizeExtensions(configuration.allowedExtensions)
        let comparisonNames = try collectNormalizedFilenames(
            under: configuration.comparisonRoots,
            configuration: configuration,
            allowedExtensions: normalizedExtensions
        )

        let sourceCandidates = try collectSourceCandidates(
            under: configuration.sourceRoots,
            configuration: configuration,
            allowedExtensions: normalizedExtensions
        )
        let groupedByName = Dictionary(grouping: sourceCandidates, by: \.normalizedFilename)

        let missingItems = sourceCandidates
            .filter { !comparisonNames.contains($0.normalizedFilename) }
            .map { candidate in
                SyncPlanItem(
                    filename: candidate.filename,
                    normalizedFilename: candidate.normalizedFilename,
                    sourceURL: candidate.sourceURL,
                    sourceRootURL: candidate.sourceRootURL,
                    relativePath: candidate.relativePath,
                    size: candidate.size,
                    duplicateSourceCount: groupedByName[candidate.normalizedFilename]?.count ?? 1
                )
            }
            .sorted {
                if $0.filename == $1.filename {
                    return $0.sourceURL.path.localizedCaseInsensitiveCompare($1.sourceURL.path) == .orderedAscending
                }
                return $0.filename.localizedCaseInsensitiveCompare($1.filename) == .orderedAscending
            }

        let duplicateMissingNameCount = Set(
            missingItems
                .filter { $0.duplicateSourceCount > 1 }
                .map(\.normalizedFilename)
        ).count

        return SyncPlan(
            items: missingItems,
            summary: SyncPlanSummary(
                sourceFileCount: sourceCandidates.count,
                comparisonFileCount: comparisonNames.count,
                missingFileCount: missingItems.count,
                duplicateMissingNameCount: duplicateMissingNameCount
            )
        )
    }

    private static func collectNormalizedFilenames(
        under roots: [URL],
        configuration: ScanConfiguration,
        allowedExtensions: Set<String>
    ) throws -> Set<String> {
        var filenames: Set<String> = []
        for root in roots {
            for file in try enumerateFiles(
                under: root,
                allowedExtensions: allowedExtensions,
                ignoreHiddenFiles: configuration.ignoreHiddenFiles
            ) {
                filenames.insert(
                    normalizeFilename(
                        file.lastPathComponent,
                        caseSensitive: configuration.caseSensitiveFilenames
                    )
                )
            }
        }
        return filenames
    }

    private static func collectSourceCandidates(
        under roots: [URL],
        configuration: ScanConfiguration,
        allowedExtensions: Set<String>
    ) throws -> [SourceCandidate] {
        var results: [SourceCandidate] = []

        for root in roots {
            for file in try enumerateFiles(
                under: root,
                allowedExtensions: allowedExtensions,
                ignoreHiddenFiles: configuration.ignoreHiddenFiles
            ) {
                let values = try file.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
                guard values.isRegularFile == true else {
                    continue
                }

                results.append(
                    SourceCandidate(
                        filename: file.lastPathComponent,
                        normalizedFilename: normalizeFilename(
                            file.lastPathComponent,
                            caseSensitive: configuration.caseSensitiveFilenames
                        ),
                        sourceURL: file,
                        sourceRootURL: root,
                        relativePath: relativePath(for: file, from: root),
                        size: Int64(values.fileSize ?? 0)
                    )
                )
            }
        }

        return results
    }

    private static func enumerateFiles(
        under root: URL,
        allowedExtensions: Set<String>,
        ignoreHiddenFiles: Bool
    ) throws -> [URL] {
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey, .isHiddenKey],
            options: ignoreHiddenFiles ? [.skipsHiddenFiles, .skipsPackageDescendants] : [.skipsPackageDescendants]
        ) else {
            return []
        }

        var urls: [URL] = []
        for case let fileURL as URL in enumerator {
            let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
            guard values.isRegularFile == true else {
                continue
            }

            if allowedExtensions.isEmpty || allowedExtensions.contains(normalizeExtension(fileURL.pathExtension)) {
                urls.append(fileURL)
            }
        }

        return urls
    }

    private static func normalizeFilename(
        _ filename: String,
        caseSensitive: Bool
    ) -> String {
        let trimmed = filename.trimmingCharacters(in: .whitespacesAndNewlines)
        return caseSensitive ? trimmed : trimmed.lowercased()
    }

    private static func normalizeExtensions(_ extensions: Set<String>) -> Set<String> {
        Set(extensions.map(normalizeExtension))
    }

    private static func normalizeExtension(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ".", with: "")
            .lowercased()
    }

    private static func relativePath(for file: URL, from root: URL) -> String {
        let rootPath = root.standardizedFileURL.path
        let filePath = file.standardizedFileURL.path

        guard filePath.hasPrefix(rootPath) else {
            return file.lastPathComponent
        }

        let trimmed = filePath.dropFirst(rootPath.count).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return trimmed.isEmpty ? file.lastPathComponent : String(trimmed)
    }
}

private struct SourceCandidate: Hashable, Sendable {
    let filename: String
    let normalizedFilename: String
    let sourceURL: URL
    let sourceRootURL: URL
    let relativePath: String
    let size: Int64
}
