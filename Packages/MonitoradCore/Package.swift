// swift-tools-version: 5.9
// MonitoradCore — AppKit에 의존하지 않는 지표 추상화·설정·레이아웃 코어.
// ADR-0002: 새 지표는 `AdjustableMetric` 구현체 하나와 registry 등록 한 줄로 추가한다.
import PackageDescription

let package = Package(
    name: "MonitoradCore",
    platforms: [
        .macOS("26.0"),
    ],
    products: [
        .library(name: "MonitoradCore", targets: ["MonitoradCore"]),
    ],
    targets: [
        .target(
            name: "MonitoradCore",
            path: "Sources/MonitoradCore"
        ),
    ]
)
