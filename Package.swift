// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Manuscript",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "manuscript", targets: ["manuscript"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0")
    ],
    targets: [
        .executableTarget(
            name: "manuscript",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Yams", package: "Yams")
            ]
        )
    ]
)
