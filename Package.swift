// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "ChatMemoirApp",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [.executable(name: "ChatMemoirApp", targets: ["ChatMemoirApp"])],
    dependencies: [.package(path: "../ChatMemoir")],
    targets: [.executableTarget(name: "ChatMemoirApp",
        dependencies: [.product(name: "TimelineEngine", package: "ChatMemoir"),
                       .product(name: "StoryEngine", package: "ChatMemoir"),
                       .product(name: "PresentationEngine", package: "ChatMemoir")],
        path: "Sources")]
)
