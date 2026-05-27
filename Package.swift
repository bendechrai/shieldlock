// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ShieldLock",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ShieldLock", targets: ["ShieldLock"])
    ],
    targets: [
        .executableTarget(
            name: "ShieldLock",
            path: "Sources"
        )
    ]
)
