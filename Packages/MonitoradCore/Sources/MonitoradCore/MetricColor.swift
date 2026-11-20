import Foundation

/// 지표별 링 색. Core는 AppKit/SwiftUI에 의존하지 않으므로 색을 sRGB 성분으로만 표현한다.
public struct MetricColor: Equatable, Hashable {
    public let red: Double
    public let green: Double
    public let blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    /// 볼륨 지표의 파란색.
    public static let volumeBlue = MetricColor(red: 0.12, green: 0.53, blue: 1.0)

    /// 디스플레이 밝기 지표의 주황색.
    public static let brightnessOrange = MetricColor(red: 1.0, green: 0.62, blue: 0.04)
}
