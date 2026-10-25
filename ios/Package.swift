// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Skins",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SkinsCore", targets: ["SkinsCore"]), .executable(name: "SkinsPreview", targets: ["SkinsApp"])],
    targets: [
        .target(name: "SkinsCore"),
        .executableTarget(name: "SkinsApp", dependencies: ["SkinsCore"], resources: [.copy("Content")]),
        .executableTarget(name: "SkinsCoreChecks", dependencies: ["SkinsCore"], path: "Tests/SkinsCoreTests")
    ]
)
