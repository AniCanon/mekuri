// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Mekuri",
    platforms: [
        .iOS(.v18),
        .macOS(.v14),
    ],
    products: [
        .library(name: "Mekuri", targets: ["Mekuri"]),
    ],
    targets: [
        .target(name: "Mekuri", resources: [.process("MekuriFold.metal")]),
        .testTarget(name: "MekuriTests", dependencies: ["Mekuri"]),
    ]
)
