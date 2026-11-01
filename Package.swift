// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ExerciseSnacks",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "SnackCore", path: "Sources/SnackCore"),
        .executableTarget(name: "ExerciseSnacks", dependencies: ["SnackCore"], path: "Sources/ExerciseSnacks"),
        .testTarget(name: "SnackCoreTests", dependencies: ["SnackCore"], path: "Tests/SnackCoreTests"),
    ]
)
