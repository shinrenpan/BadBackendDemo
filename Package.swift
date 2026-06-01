// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BadBackendDemo",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "BadBackendDemo",
            path: "Sources/BadBackendDemo"
        )
    ]
)
