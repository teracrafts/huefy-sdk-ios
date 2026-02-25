// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "huefy-swift",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        .library(
            name: "Huefy",
            targets: ["Huefy"]
        ),
    ],
    targets: [
        .target(
            name: "Huefy",
            path: "Sources/Huefy"
        ),
        .testTarget(
            name: "HuefyTests",
            dependencies: ["Huefy"],
            path: "Tests/HuefyTests"
        ),
    ]
)
