import Foundation
import XCTest
@testable import SyncByNameCore

final class FilenameSyncPlannerTests: XCTestCase {
    func testBuildPlanFindsFilesMissingByFilenameAcrossRoots() throws {
        let root = temporaryDirectory()
        let sourceRoot = root.appendingPathComponent("Source", isDirectory: true)
        let comparisonRoot = root.appendingPathComponent("Comparison", isDirectory: true)

        try makeFile(at: sourceRoot.appendingPathComponent("A/video-1.mp4"), contents: "one")
        try makeFile(at: sourceRoot.appendingPathComponent("B/video-2.mp4"), contents: "two")
        try makeFile(at: comparisonRoot.appendingPathComponent("Elsewhere/video-2.mp4"), contents: "two")

        let plan = try FilenameSyncPlanner.buildPlan(
            configuration: ScanConfiguration(
                sourceRoots: [sourceRoot],
                comparisonRoots: [comparisonRoot],
                allowedExtensions: ["mp4"]
            )
        )

        XCTAssertEqual(plan.summary.sourceFileCount, 2)
        XCTAssertEqual(plan.summary.comparisonFileCount, 1)
        XCTAssertEqual(plan.summary.missingFileCount, 1)
        XCTAssertEqual(plan.items.first?.filename, "video-1.mp4")
    }

    func testBuildPlanFiltersExtensionsCaseInsensitively() throws {
        let root = temporaryDirectory()
        let sourceRoot = root.appendingPathComponent("Source", isDirectory: true)
        let comparisonRoot = root.appendingPathComponent("Comparison", isDirectory: true)

        try makeFile(at: sourceRoot.appendingPathComponent("clip.MOV"), contents: "movie")
        try makeFile(at: sourceRoot.appendingPathComponent("notes.txt"), contents: "text")

        let plan = try FilenameSyncPlanner.buildPlan(
            configuration: ScanConfiguration(
                sourceRoots: [sourceRoot],
                comparisonRoots: [comparisonRoot],
                allowedExtensions: ["mov"]
            )
        )

        XCTAssertEqual(plan.summary.sourceFileCount, 1)
        XCTAssertEqual(plan.summary.missingFileCount, 1)
        XCTAssertEqual(plan.items.first?.filename, "clip.MOV")
    }

    func testBuildPlanReportsDuplicateMissingSourceNames() throws {
        let root = temporaryDirectory()
        let sourceA = root.appendingPathComponent("SourceA", isDirectory: true)
        let sourceB = root.appendingPathComponent("SourceB", isDirectory: true)
        let comparisonRoot = root.appendingPathComponent("Comparison", isDirectory: true)

        try makeFile(at: sourceA.appendingPathComponent("dup/file.mov"), contents: "one")
        try makeFile(at: sourceB.appendingPathComponent("other/file.mov"), contents: "two")

        let plan = try FilenameSyncPlanner.buildPlan(
            configuration: ScanConfiguration(
                sourceRoots: [sourceA, sourceB],
                comparisonRoots: [comparisonRoot],
                allowedExtensions: ["mov"]
            )
        )

        XCTAssertEqual(plan.summary.missingFileCount, 2)
        XCTAssertEqual(plan.summary.duplicateMissingNameCount, 1)
        XCTAssertTrue(plan.items.allSatisfy { $0.duplicateSourceCount == 2 })
    }

    func testBuildPlanRespectsCaseSensitiveMatchingWhenEnabled() throws {
        let root = temporaryDirectory()
        let sourceRoot = root.appendingPathComponent("Source", isDirectory: true)
        let comparisonRoot = root.appendingPathComponent("Comparison", isDirectory: true)

        try makeFile(at: sourceRoot.appendingPathComponent("clip.MOV"), contents: "movie")
        try makeFile(at: comparisonRoot.appendingPathComponent("clip.mov"), contents: "movie")

        let plan = try FilenameSyncPlanner.buildPlan(
            configuration: ScanConfiguration(
                sourceRoots: [sourceRoot],
                comparisonRoots: [comparisonRoot],
                allowedExtensions: ["mov"],
                caseSensitiveFilenames: true
            )
        )

        XCTAssertEqual(plan.summary.missingFileCount, 1)
        XCTAssertEqual(plan.items.first?.filename, "clip.MOV")
    }

    private func temporaryDirectory() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    private func makeFile(at url: URL, contents: String) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try contents.data(using: .utf8)?.write(to: url)
    }
}
