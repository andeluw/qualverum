// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RAGCore",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "RAGCore",
            targets: ["RAGCore"]
        ),
        .library(
            name: "RAGVectura",
            targets: ["RAGVectura"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/john-rocky/CoreML-LLM.git",
            from: "1.9.0"
        ),
        .package(
            url: "https://github.com/rryam/VecturaKit.git",
            from: "6.3.0"
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "RAGCore",
            dependencies: [
                .product(
                    name: "CoreMLLLM",
                    package: "CoreML-LLM"
                )
            ]
        ),
        .target(
            name: "RAGVectura",
            dependencies: [
                "RAGCore",
                .product(
                    name: "VecturaKit",
                    package: "VecturaKit"
                ),
            ]
        ),
        .testTarget(
            name: "RAGCoreTests",
            dependencies: ["RAGCore"]
        ),
        .testTarget(
            name: "RAGVecturaTests",
            dependencies: [
                "RAGCore",
                "RAGVectura",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
