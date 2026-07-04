// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "ChatMemoirApp",
    platforms: [.iOS(.v17)],
    products: [.executable(name: "ChatMemoirApp", targets: ["ChatMemoirApp"])],
    dependencies: [],
    targets: [.executableTarget(name: "ChatMemoirApp", dependencies: [], path: "Sources")]
)
