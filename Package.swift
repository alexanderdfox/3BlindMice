// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ThreeBlindMice",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "ThreeBlindMice",
            targets: ["ThreeBlindMice"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ThreeBlindMice",
            dependencies: [],
            path: ".",
            sources: ["3BlindMiceApp.swift"]
        )
    ]
)
