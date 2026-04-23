// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mantel",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "mantel"
        ),
        .testTarget(
            name: "mantelTests",
            dependencies: ["mantel"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
