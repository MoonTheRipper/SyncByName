import XCTest
@testable import SyncByNameCore

final class UpdateModelsTests: XCTestCase {
    func testSemanticVersionsCompareNumerically() {
        XCTAssertLessThan(AppVersion("v0.2.0"), AppVersion("v0.2.1"))
        XCTAssertLessThan(AppVersion("1.9"), AppVersion("1.10"))
        XCTAssertEqual(AppVersion("1.0.0"), AppVersion("v1.0"))
    }

    func testEquivalentVersionsRemainHashCompatible() {
        let versions: Set<AppVersion> = [
            AppVersion("1.0.0"),
            AppVersion("v1.0")
        ]

        XCTAssertEqual(versions.count, 1)
    }

    func testUpdateInfoDetectsNewerRelease() {
        let release = AppRelease(
            id: 1,
            tagName: "v0.3.0",
            name: "v0.3.0",
            body: "",
            htmlURL: URL(string: "https://example.com/release")!,
            draft: false,
            prerelease: false,
            publishedAt: nil,
            assets: []
        )

        let update = AppUpdateInfo(
            currentVersion: "0.2.1",
            release: release,
            preferredAsset: nil
        )

        XCTAssertTrue(update.isNewerThanCurrentVersion)
    }
}
