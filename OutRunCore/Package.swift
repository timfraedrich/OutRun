// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OutRunCore",
    defaultLocalization: "en",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "OutRunCore", targets: ["OutRunCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mac-cain13/R.swift.git", from: "7.8.0"),
        .package(url: "https://github.com/apple/swift-nio", from: "2.84.0"),
        .package(url: "https://github.com/pointfreeco/swift-perception", from: "2.0.6"),
        .package(url: "https://github.com/hyperoslo/Cache", from: "7.4.0"),
    ],
    targets: [
        .target(
            name: "OutRunCore",
            dependencies: [
                .product(name: "RswiftLibrary", package: "r.swift"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "Perception", package: "swift-perception"),
                .product(name: "Cache", package: "Cache"),
            ],
            plugins: [.plugin(name: "RswiftGenerateInternalResources", package: "r.swift")]
        ),
        .testTarget(
            name: "OutRunCoreTests",
            dependencies: ["OutRunCore"],
            resources: [.process("ExampleData")]
        ),
    ]
)
