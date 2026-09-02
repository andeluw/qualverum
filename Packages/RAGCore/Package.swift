// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RAGCore",
    platforms: [
        .macOS(.v26),
        .iOS(.v26)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "RAGCore",
            targets: ["RAGCore"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "RAGCore"
        ),
        .testTarget(
            name: "RAGCoreTests",
            dependencies: ["RAGCore"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
