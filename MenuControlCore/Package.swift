// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MenuControlCore",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "MenuControlCore", targets: ["MenuControlCore"]),
        .library(name: "MenuControlUI", targets: ["MenuControlUI"])
    ],
    targets: [
        .target(
            name: "MenuControlCore",
            resources: [.copy("Resources/menu_catalog_carbs.json")]
        ),
        .target(
            name: "MenuControlUI",
            dependencies: ["MenuControlCore"]
        ),
        .testTarget(
            name: "MenuControlCoreTests",
            dependencies: ["MenuControlCore"]
        ),
        .testTarget(
            name: "MenuControlUITests",
            dependencies: ["MenuControlUI"]
        )
    ]
)
