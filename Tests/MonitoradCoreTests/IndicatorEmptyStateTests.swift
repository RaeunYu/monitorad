import MonitoradCore
import XCTest

/// 선택된 지표가 모두 사용 불가일 때의 placeholder 사유 (P3 edge).
final class IndicatorEmptyStateTests: XCTestCase {
    func testMessageJoinsUnavailableReasons() {
        let first = MockAdjustableMetric(id: "a", availability: .unavailable(reason: "사유 A"))
        let second = MockAdjustableMetric(id: "b", availability: .unavailable(reason: "사유 B"))

        let message = IndicatorEmptyState.message(for: [first, second])

        XCTAssertEqual(message, "사유 A 사유 B")
    }

    func testMessageDeduplicatesIdenticalReasons() {
        let first = MockAdjustableMetric(id: "a", availability: .unavailable(reason: "같은 사유"))
        let second = MockAdjustableMetric(id: "b", availability: .unavailable(reason: "같은 사유"))

        XCTAssertEqual(IndicatorEmptyState.message(for: [first, second]), "같은 사유")
    }

    func testMessageFallsBackToDefaultWhenEveryMetricIsAvailable() {
        let available = MockAdjustableMetric(id: "a")
        XCTAssertEqual(IndicatorEmptyState.message(for: [available]), IndicatorEmptyState.defaultMessage)
        XCTAssertEqual(IndicatorEmptyState.message(for: []), IndicatorEmptyState.defaultMessage)
    }

    func testDeselectingLastAvailableMetricLeavesEmptyRingsWithReason() {
        // 선택 2개 중 사용 가능한 1개를 해제 → 남은 1개가 unavailable이면 링은 0개가 된다.
        let volume = MockAdjustableMetric(id: "volume")
        let brightness = MockAdjustableMetric(
            id: "brightness",
            availability: .unavailable(reason: "내장 디스플레이가 없어 밝기를 읽을 수 없습니다")
        )
        let registry = MetricRegistry(metrics: [volume, brightness])
        var selection = ["volume", "brightness"]

        selection = MetricSelectionPolicy.toggling(
            "volume",
            selectedIDs: selection,
            knownMetricIDs: registry.ids
        )

        XCTAssertEqual(selection, ["brightness"])
        XCTAssertEqual(selection.count, MonitoradSettings.minimumSelectedMetrics)
        XCTAssertTrue(registry.resolveDisplayMetrics(selectedIDs: selection).isEmpty)
        XCTAssertEqual(
            IndicatorEmptyState.message(for: registry.resolveAll(selectedIDs: selection)),
            "내장 디스플레이가 없어 밝기를 읽을 수 없습니다"
        )
    }
}
