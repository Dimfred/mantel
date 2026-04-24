// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mantel",
    platforms: [.macOS(.v13)],
    products: [
        .library(
            name: "MantelCore",
            targets: ["MantelCore"]
        ),
        .executable(
            name: "mantel",
            targets: ["mantel"]
        ),
    ],
    targets: [
        .target(
            name: "MantelCore",
            path: "Sources/mantel"
        ),
        .executableTarget(
            name: "mantel",
            dependencies: ["MantelCore"],
            path: "Sources/mantel-bin"
        ),
        .testTarget(
            name: "MantelCoreTests",
            dependencies: ["MantelCore"],
            path: "Tests/mantelTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
