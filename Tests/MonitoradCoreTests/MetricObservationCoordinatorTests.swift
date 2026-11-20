import MonitoradCore
import XCTest

/// 관측 시작·중지와 변경 콜백 전달.
final class MetricObservationCoordinatorTests: XCTestCase {
    func testObserveStartsOnlySelectedMetrics() {
        let first = MockAdjustableMetric(id: "a")
        let second = MockAdjustableMetric(id: "b")
        let coordinator = MetricObservationCoordinator(registry: MetricRegistry(metrics: [first, second]))

        coordinator.observe(metricIDs: ["a"])

        XCTAssertEqual(first.startObservingCount, 1)
        XCTAssertEqual(second.startObservingCount, 0)
        XCTAssertEqual(coordinator.observedIDs, ["a"])
    }

    func testObserveStopsDeselectedMetrics() {
        let first = MockAdjustableMetric(id: "a")
        let second = MockAdjustableMetric(id: "b")
        let coordinator = MetricObservationCoordinator(registry: MetricRegistry(metrics: [first, second]))

        coordinator.observe(metricIDs: ["a", "b"])
        coordinator.observe(metricIDs: ["b"])

        XCTAssertEqual(first.startObservingCount, 1)
        XCTAssertEqual(first.stopObservingCount, 1)
        XCTAssertEqual(second.stopObservingCount, 0)
        XCTAssertEqual(coordinator.observedIDs, ["b"])
    }

    func testObserveIsIdempotent() {
        let metric = MockAdjustableMetric(id: "a")
        let coordinator = MetricObservationCoordinator(registry: MetricRegistry(metrics: [metric]))

        coordinator.observe(metricIDs: ["a"])
        coordinator.observe(metricIDs: ["a"])

        XCTAssertEqual(metric.startObservingCount, 1)
    }

    func testChangeHandlerReceivesMetricIDAndValue() {
        let metric = MockAdjustableMetric(id: "a")
        let coordinator = MetricObservationCoordinator(registry: MetricRegistry(metrics: [metric]))
        var received: [(String, Double)] = []
        coordinator.setChangeHandler { metricID, value in
            received.append((metricID, value))
        }

        coordinator.observe(metricIDs: ["a"])
        metric.sendValue(0.42)

        XCTAssertEqual(received.count, 1)
        XCTAssertEqual(received.first?.0, "a")
        XCTAssertEqual(received.first?.1 ?? 0, 0.42, accuracy: 0.0001)
    }

    func testStopAllStopsObservedMetrics() {
        let first = MockAdjustableMetric(id: "a")
        let second = MockAdjustableMetric(id: "b")
        let coordinator = MetricObservationCoordinator(registry: MetricRegistry(metrics: [first, second]))

        coordinator.observe(metricIDs: ["a", "b"])
        coordinator.stopAll()

        XCTAssertEqual(first.stopObservingCount, 1)
        XCTAssertEqual(second.stopObservingCount, 1)
        XCTAssertTrue(coordinator.observedIDs.isEmpty)
    }

    func testUnavailableMetricIsStillObservableForRecovery() {
        let metric = MockAdjustableMetric(id: "a", availability: .unavailable(reason: "로드 실패"))
        let coordinator = MetricObservationCoordinator(registry: MetricRegistry(metrics: [metric]))

        coordinator.observe(metricIDs: ["a"])
        XCTAssertEqual(metric.startObservingCount, 1)
    }
}
