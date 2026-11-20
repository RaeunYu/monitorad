import Foundation

/// 메뉴바 인디케이터의 링 배치 (ADR-0003).
///
/// 항목 하나에 최대 3지표를 담는다. 지표 1개면 큰 링(약 20pt), 2~3개면 작은 링을 나란히 둔다.
/// 4개 이상과 0개는 배치를 만들지 않고 nil을 반환한다(호출자가 placeholder를 그린다).
public struct IndicatorLayout: Equatable {
    /// 링 하나의 크기 구분.
    public enum RingSize: Equatable {
        /// 지표 1개일 때의 큰 링.
        case large
        /// 지표 2~3개일 때의 작은 링.
        case small
    }

    /// 배치를 만들 수 있는 최대 지표 수.
    public static let maximumMetricCount = MonitoradSettings.maximumSelectedMetrics

    /// 큰 링의 지름(pt).
    public static let largeRingDiameter = 20.0

    /// 작은 링의 지름(pt).
    public static let smallRingDiameter = 15.0

    /// 작은 링 사이 간격(pt).
    public static let smallRingSpacing = 2.0

    /// 항목 좌우 여백(pt).
    public static let horizontalInset = 3.0

    /// 메뉴바 항목 높이(pt). `NSStatusBar.system.thickness` 실측값과 같다.
    public static let height = 22.0

    public let ringSize: RingSize
    public let metricCount: Int
    /// 링 지름(pt).
    public let ringDiameter: Double
    /// 링 사이 간격(pt). 큰 링 하나면 0이다.
    public let ringSpacing: Double
    /// 좌우 여백(pt).
    public let horizontalInset: Double
    /// 항목 높이(pt).
    public let height: Double

    /// status item에 배정할 폭. 링·간격·여백의 합이다.
    public var itemWidth: Double {
        horizontalInset * 2 + ringDiameter * Double(metricCount) + ringSpacing * Double(metricCount - 1)
    }

    /// 지표 수에 맞는 배치. 1개는 큰 링, 2~3개는 작은 링이며 그 밖은 nil.
    public static func resolve(metricCount: Int) -> IndicatorLayout? {
        switch metricCount {
        case 1:
            return IndicatorLayout(
                ringSize: .large,
                metricCount: 1,
                ringDiameter: largeRingDiameter,
                ringSpacing: 0,
                horizontalInset: horizontalInset,
                height: height
            )
        case 2...maximumMetricCount:
            return IndicatorLayout(
                ringSize: .small,
                metricCount: metricCount,
                ringDiameter: smallRingDiameter,
                ringSpacing: smallRingSpacing,
                horizontalInset: horizontalInset,
                height: height
            )
        default:
            return nil
        }
    }
}
