// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OutRunCore",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "OutRunCore", targets: ["OutRunCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/JohnEstropia/CoreStore", from: "7.3.0")
    ],
    targets: [
        .target(name: "OutRunCore", dependencies: ["CoreStore"]),
        .testTarget(name: "OutRunCoreTests", dependencies: ["OutRunCore"], resources: [.process("ExampleData")])
    ]
)
