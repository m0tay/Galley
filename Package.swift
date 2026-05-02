// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "Galley",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "Galley", targets: ["Galley"])
    ],
    dependencies: [],
    targets: [
        // Entry point only — @main + AppDelegate live here
        .executableTarget(
            name: "Galley",
            dependencies: ["GalleyLib"]
        ),
        // All business logic and UI — importable by tests
        .target(
            name: "GalleyLib",
            dependencies: []
        ),
        .testTarget(
            name: "GalleyTests",
            dependencies: ["GalleyLib"]
        )
    ]
)
