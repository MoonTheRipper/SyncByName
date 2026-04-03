import Foundation
import XCTest
@testable import SyncByNameCore

final class CopyEngineTests: XCTestCase {
    func testCopyPreservesSourceRootStructure() throws {
        let base = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let sourceRoot = base.appendingPathComponent("SourceDrive", isDirectory: true)
        let outputRoot = base.appendingPathComponent("Output", isDirectory: true)
        let fileURL = sourceRoot.appendingPathComponent("Nested/clip.mp4")

        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("hello".utf8).write(to: fileURL)

        let plan = SyncPlan(
            items: [
                SyncPlanItem(
                    filename: "clip.mp4",
                    normalizedFilename: "clip.mp4",
                    sourceURL: fileURL,
                    sourceRootURL: sourceRoot,
                    relativePath: "Nested/clip.mp4",
                    size: 5,
                    duplicateSourceCount: 1
                )
            ],
            summary: SyncPlanSummary(
                sourceFileCount: 1,
                comparisonFileCount: 0,
                missingFileCount: 1,
                duplicateMissingNameCount: 0
            )
        )

        let result = try CopyEngine.copy(
            plan: plan,
            configuration: CopyConfiguration(
                outputRoot: outputRoot,
                preserveSourceFolders: true
            )
        )

        let expected = outputRoot.appendingPathComponent("SourceDrive/Nested/clip.mp4")
        XCTAssertEqual(result.copiedDestinations, [expected])
        XCTAssertTrue(FileManager.default.fileExists(atPath: expected.path))
    }
}
