// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OutRunComponents",
    platforms: [.iOS(.v17)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "OutRunCore", targets: ["OutRunCore"]),
        .library(name: "OutRunDatabase", targets: ["OutRunDatabase"]),
        .library(name: "OutRunRecording", targets: ["OutRunRecording"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(name: "OutRunCore", dependencies: ["OutRunDatabase", "OutRunRecording"]),
        .target(name: "OutRunDatabase"),
        .target(name: "OutRunRecording"),

    ]
)
