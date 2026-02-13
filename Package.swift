// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KlacApp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "KlacApp", targets: ["KlacApp"])
    ],
    targets: [
        .executableTarget(
            name: "KlacApp",
            resources: [
                .process("Resources")
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("AVFoundation")
            ]
        )
    ]
)
