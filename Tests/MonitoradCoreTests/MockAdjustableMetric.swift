import Foundation
import MonitoradCore

/// 단위 테스트용 지표 구현. ADR-0002의 `AdjustableMetric` 경계를 그대로 구현한다.
/// 3링·최대 3지표 검증은 이 목업 지표로 수행한다(이슈 #2 수용 기준).
final class MockAdjustableMetric: AdjustableMetric {
    let id: String
    let displayName: String
    let symbolName: String
    let tint: MetricColor

    var value: Double
    var availability: MetricAvailability
    var onChange: ((Double) -> Void)?

    private(set) var startObservingCount = 0
    private(set) var stopObservingCount = 0

    init(
        id: String,
        displayName: String = "목업 지표",
        symbolName: String = "circle",
        tint: MetricColor = MetricColor(red: 0, green: 0, blue: 0),
        value: Double = 0.5,
        availability: MetricAvailability = .available
    ) {
        self.id = id
        self.displayName = displayName
        self.symbolName = symbolName
        self.tint = tint
        self.value = value
        self.availability = availability
    }

    func startObserving() {
        startObservingCount += 1
    }

    func stopObserving() {
        stopObservingCount += 1
    }

    /// 관측 중 값 변경을 흉내 낸다.
    func sendValue(_ newValue: Double) {
        value = newValue
        onChange?(newValue)
    }
}
