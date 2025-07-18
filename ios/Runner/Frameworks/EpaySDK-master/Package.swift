// swift-tools-version:5.3

// This file was autogenerated, do not modify

import PackageDescription

let package = Package(
    name: "EpaySDK",
    defaultLocalization: "ru",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "EpaySDK",
            targets: ["EpaySDK"]
        ),
        .library(
            name: "CardScan",
            targets: ["CardScan"]
        )
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "CardScan",
            path: "StaticFrameworks/CardScan/CardScan.xcframework"
        ),
        .target(
            name: "EpaySDK",
            dependencies: [
                .byName(name: "CardScan")
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
