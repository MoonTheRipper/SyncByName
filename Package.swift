// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SyncByName",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "SyncByName",
            targets: ["SyncByNameApp"]
        ),
        .library(
            name: "SyncByNameCore",
            targets: ["SyncByNameCore"]
        )
    ],
    targets: [
        .executableTarget(
            name: "SyncByNameApp",
            dependencies: ["SyncByNameCore"],
            path: "Sources/SyncByNameApp",
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "SyncByNameCore",
            path: "Sources/SyncByNameCore"
        ),
        .testTarget(
            name: "SyncByNameCoreTests",
            dependencies: ["SyncByNameCore"],
            path: "Tests/SyncByNameCoreTests"
        )
    ]
)
