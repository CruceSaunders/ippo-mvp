// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "IppoMVP",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "IppoMVP",
            targets: ["IppoMVP"]
        ),
    ],
    targets: [
        .target(
            name: "IppoMVP",
            dependencies: [],
            path: "IppoMVP",
            exclude: ["IppoMVPApp.swift", "ContentView.swift", "UI", "Services/WatchConnectivityService.swift", "Utils/HapticsManager.swift"],
            sources: [
                "Config",
                "Core/Types",
                "Data",
                "Engine",
                "Systems",
                "Services/DataPersistence.swift",
                "Services/AuthService.swift",
                "Services/CloudService.swift",
                "Utils/TelemetryLogger.swift"
            ]
        ),
        .testTarget(
            name: "IppoMVPTests",
            dependencies: ["IppoMVP"],
            path: "IppoMVPTests"
        ),
    ]
)
