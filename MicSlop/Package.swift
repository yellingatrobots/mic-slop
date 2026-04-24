// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MicSlop",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.0.0")
    ],
    targets: [
        .executableTarget(
            name: "MicSlop",
            dependencies: ["KeyboardShortcuts"]
        )
    ]
)
