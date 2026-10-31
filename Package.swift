// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Snacks",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "SnackCore", path: "Sources/SnackCore"),
        .executableTarget(name: "Snacks", dependencies: ["SnackCore"], path: "Sources/Snacks"),
        .testTarget(name: "SnackCoreTests", dependencies: ["SnackCore"], path: "Tests/SnackCoreTests"),
    ]
)
