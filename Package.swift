// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "P5CommandLab",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "P5CommandLabCore", targets: ["P5CommandLabCore"]),
        .executable(name: "P5CommandLab", targets: ["P5CommandLab"])
    ],
    targets: [
        .target(name: "P5CommandLabCore"),
        .executableTarget(
            name: "P5CommandLab",
            dependencies: ["P5CommandLabCore"]
        ),
        .testTarget(
            name: "P5CommandLabCoreTests",
            dependencies: ["P5CommandLabCore"]
        )
    ]
)
