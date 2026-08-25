// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "gamepads_ios",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "gamepads-ios", targets: ["gamepads_ios"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "gamepads_ios",
            dependencies: [],
            linkerSettings: [
                .linkedFramework("GameController")
            ]
        )
    ]
)
