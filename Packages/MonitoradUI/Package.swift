// swift-tools-version: 5.9
// MonitoradUI — 메뉴바 링 인디케이터와 팝오버의 SwiftUI 뷰.
import PackageDescription

let package = Package(
    name: "MonitoradUI",
    platforms: [
        .macOS("26.0"),
    ],
    products: [
        .library(name: "MonitoradUI", targets: ["MonitoradUI"]),
    ],
    dependencies: [
        .package(path: "../MonitoradCore"),
    ],
    targets: [
        .target(
            name: "MonitoradUI",
            dependencies: ["MonitoradCore"],
            path: "Sources/MonitoradUI"
        ),
    ]
)
