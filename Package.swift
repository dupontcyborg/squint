// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "Squint",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Squint", targets: ["Squint"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Squint",
            dependencies: [],
            path: "Squint",
            exclude: ["Info.plist", "AppIcon.icns"]
        )
    ]
)
