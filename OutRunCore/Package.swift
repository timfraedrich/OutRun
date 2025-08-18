// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OutRunCore",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "OutRunCore", targets: ["OutRunCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/JohnEstropia/CoreStore", from: "7.3.0"),
        .package(url: "https://github.com/mac-cain13/R.swift.git", from: "7.8.0"),
        .package(url: "https://github.com/apple/swift-nio", from: "2.84.0"),
    ],
    targets: [
        .target(
            name: "OutRunCore",
            dependencies: [
                "CoreStore",
                .product(name: "RswiftLibrary", package: "r.swift"),
                .product(name: "NIOCore", package: "swift-nio")
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
