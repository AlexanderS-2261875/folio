// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Folio",
    platforms: [.macOS(.v26)],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-markdown.git", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "Folio",
            dependencies: [.product(name: "Markdown", package: "swift-markdown")],
            path: "Sources/Folio"
        ),
    ]
)
