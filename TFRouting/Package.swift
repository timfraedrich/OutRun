// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TFRouting",
    defaultLocalization: "en",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "TFRouting", targets: ["TFRouting"]),
    ],
    targets: [
        .target(name: "TFRouting"),
        .target(name: "TFRoutingExample", dependencies: ["TFRouting"]),
    ]
)
