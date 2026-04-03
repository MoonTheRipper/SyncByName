import Foundation

public struct ScanConfiguration: Hashable, Sendable {
    public var sourceRoots: [URL]
    public var comparisonRoots: [URL]
    public var allowedExtensions: Set<String>
    public var caseSensitiveFilenames: Bool
    public var ignoreHiddenFiles: Bool

    public init(
        sourceRoots: [URL],
        comparisonRoots: [URL],
        allowedExtensions: Set<String> = [],
        caseSensitiveFilenames: Bool = false,
        ignoreHiddenFiles: Bool = true
    ) {
        self.sourceRoots = sourceRoots
        self.comparisonRoots = comparisonRoots
        self.allowedExtensions = allowedExtensions
        self.caseSensitiveFilenames = caseSensitiveFilenames
        self.ignoreHiddenFiles = ignoreHiddenFiles
    }
}

public struct SyncPlanItem: Hashable, Sendable, Identifiable {
    public let id: String
    public let filename: String
    public let normalizedFilename: String
    public let sourceURL: URL
    public let sourceRootURL: URL
    public let relativePath: String
    public let size: Int64
    public let duplicateSourceCount: Int

    public init(
        filename: String,
        normalizedFilename: String,
        sourceURL: URL,
        sourceRootURL: URL,
        relativePath: String,
        size: Int64,
        duplicateSourceCount: Int
    ) {
        self.id = sourceURL.path
        self.filename = filename
        self.normalizedFilename = normalizedFilename
        self.sourceURL = sourceURL
        self.sourceRootURL = sourceRootURL
        self.relativePath = relativePath
        self.size = size
        self.duplicateSourceCount = duplicateSourceCount
    }
}

public struct SyncPlanSummary: Hashable, Sendable {
    public let sourceFileCount: Int
    public let comparisonFileCount: Int
    public let missingFileCount: Int
    public let duplicateMissingNameCount: Int

    public init(
        sourceFileCount: Int,
        comparisonFileCount: Int,
        missingFileCount: Int,
        duplicateMissingNameCount: Int
    ) {
        self.sourceFileCount = sourceFileCount
        self.comparisonFileCount = comparisonFileCount
        self.missingFileCount = missingFileCount
        self.duplicateMissingNameCount = duplicateMissingNameCount
    }
}

public struct SyncPlan: Hashable, Sendable {
    public let generatedAt: Date
    public let items: [SyncPlanItem]
    public let summary: SyncPlanSummary

    public init(
        generatedAt: Date = Date(),
        items: [SyncPlanItem],
        summary: SyncPlanSummary
    ) {
        self.generatedAt = generatedAt
        self.items = items
        self.summary = summary
    }
}

public struct CopyConfiguration: Hashable, Sendable {
    public let outputRoot: URL
    public let preserveSourceFolders: Bool
    public let replaceExisting: Bool

    public init(
        outputRoot: URL,
        preserveSourceFolders: Bool = true,
        replaceExisting: Bool = false
    ) {
        self.outputRoot = outputRoot
        self.preserveSourceFolders = preserveSourceFolders
        self.replaceExisting = replaceExisting
    }
}

public struct CopyFailure: Hashable, Sendable, Identifiable {
    public let id: String
    public let item: SyncPlanItem
    public let reason: String

    public init(item: SyncPlanItem, reason: String) {
        self.id = "\(item.id)::\(reason)"
        self.item = item
        self.reason = reason
    }
}

public struct CopyResult: Hashable, Sendable {
    public let copiedDestinations: [URL]
    public let skippedItems: [SyncPlanItem]
    public let failures: [CopyFailure]

    public init(
        copiedDestinations: [URL],
        skippedItems: [SyncPlanItem],
        failures: [CopyFailure]
    ) {
        self.copiedDestinations = copiedDestinations
        self.skippedItems = skippedItems
        self.failures = failures
    }
}
