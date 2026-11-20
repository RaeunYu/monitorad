import MonitoradCore
import XCTest

/// 선택된 목업 지표 → 링·레이아웃·빈 상태 사유 변환(표시 조합 검증).
final class IndicatorPresentationTests: XCTestCase {
    private func makeMetrics(values: [Double], available: Bool = true) -> [MockAdjustableMetric] {
        values.enumerated().map { index, value in
            MockAdjustableMetric(
                id: "metric-\(index)",
                displayName: "지표 \(index)",
                symbolName: "circle",
                tint: MetricColor(red: Double(index) / 10, green: 0, blue: 0),
                value: value,
                availability: available ? .available : .unavailable(reason: "사용 불가")
            )
        }
    }

    func testThreeAvailableMetricsMapToThreeSmallRings() {
        let metrics = makeMetrics(values: [0.2, 0.5, 0.8])

        let presentation = IndicatorPresentation.resolve(selectedMetrics: metrics)

        XCTAssertEqual(presentation.rings.map(\.id), ["metric-0", "metric-1", "metric-2"])
        XCTAssertEqual(presentation.rings.map(\.name), ["지표 0", "지표 1", "지표 2"])
        XCTAssertEqual(presentation.rings.map(\.value), [0.2, 0.5, 0.8])
        XCTAssertEqual(presentation.layout?.ringSize, .small)
        XCTAssertEqual(presentation.layout?.metricCount, 3)
        XCTAssertNil(presentation.placeholderReason)
    }

    func testSingleMetricUsesLargeRing() {
        let presentation = IndicatorPresentation.resolve(selectedMetrics: makeMetrics(values: [0.3]))

        XCTAssertEqual(presentation.rings.count, 1)
        XCTAssertEqual(presentation.layout?.ringSize, .large)
    }

    func testUnavailableMetricIsFilteredFromRings() {
        let available = MockAdjustableMetric(id: "available")
        let unavailable = MockAdjustableMetric(
            id: "unavailable",
            availability: .unavailable(reason: "사용 불가")
        )

        let presentation = IndicatorPresentation.resolve(selectedMetrics: [available, unavailable])

        XCTAssertEqual(presentation.rings.map(\.id), ["available"])
        XCTAssertEqual(presentation.layout?.ringSize, .large)
        XCTAssertNil(presentation.placeholderReason)
    }

    func testAllUnavailableMetricsProduceEmptyRingsAndReason() {
        let unavailable = MockAdjustableMetric(
            id: "unavailable",
            availability: .unavailable(reason: "내장 디스플레이가 없습니다")
        )

        let presentation = IndicatorPresentation.resolve(selectedMetrics: [unavailable])

        XCTAssertTrue(presentation.rings.isEmpty)
        XCTAssertNil(presentation.layout)
        XCTAssertEqual(presentation.placeholderReason, "내장 디스플레이가 없습니다")
    }

    func testRingValueIsClampedToUnitRange() {
        let high = MockAdjustableMetric(id: "high", value: 1.7)
        let low = MockAdjustableMetric(id: "low", value: -0.2)

        let presentation = IndicatorPresentation.resolve(selectedMetrics: [high, low])

        XCTAssertEqual(presentation.rings.map(\.value), [1.0, 0.0])
    }
}
