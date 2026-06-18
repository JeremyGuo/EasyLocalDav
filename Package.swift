// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EasyLocalDav",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "EasyLocalDav", targets: ["EasyLocalDav"])
    ],
    targets: [
        .executableTarget(
            name: "EasyLocalDav",
            path: "Sources/EasyLocalDav"
        )
    ],
    swiftLanguageVersions: [.v5]
)
