// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HuefySDK",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "HuefySDK",
            targets: ["HuefySDK"]
        ),
    ],
    dependencies: [
        // No external dependencies - using URLSession for networking
    ],
    targets: [
        .target(
            name: "HuefySDK",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "HuefySDKTests",
            dependencies: ["HuefySDK"],
            path: "Tests"
        ),
    ]
)