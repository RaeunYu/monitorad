import MonitoradCore
import SwiftUI

public extension Color {
    /// Core의 sRGB 색 표현을 SwiftUI 색으로 바꾼다.
    init(_ metricColor: MetricColor) {
        self.init(
            .sRGB,
            red: metricColor.red,
            green: metricColor.green,
            blue: metricColor.blue,
            opacity: 1.0
        )
    }
}
