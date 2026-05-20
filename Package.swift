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
    dependencies: [
        // Keep version in sync with SPARKLE_VERSION in .github/workflows/release.yml.
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.9.2"),
    ],
    targets: [
        .executableTarget(
            name: "Squint",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "Squint",
            exclude: ["Info.plist", "AppIcon.icns", "AppIcon.png"],
            linkerSettings: [
                // Resolve embedded frameworks (Sparkle) from the app bundle at runtime.
                // SwiftPM doesn't add this rpath for executables, so we set it explicitly.
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])
            ]
        ),
        .testTarget(
            name: "SquintTests",
            dependencies: ["Squint"],
            path: "SquintTests"
        )
    ]
)
