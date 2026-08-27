// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MagicShopCore",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "MagicShopCore", targets: ["MagicShopCore"])
    ],
    targets: [
        .target(
            name: "MagicShopCore",
            path: "MagicShop/Core"
        ),
        .testTarget(
            name: "MagicShopCoreTests",
            dependencies: ["MagicShopCore"],
            path: "MagicShopTests"
        )
    ]
)
