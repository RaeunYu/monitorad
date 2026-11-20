import MonitoradCore
import XCTest

/// registry 전체 관측과 변경 콜백. 해제된 지표도 availability 갱신을 위해 계속 관측한다(P3).
final class MetricObservationCoordinatorTests: XCTestCase {
    func testStartObservesEveryRegisteredMetric() {
        let first = MockAdjustableMetric(id: "a")
        let second = MockAdjustableMetric(id: "b")
        let coordinator = MetricObservationCoordinator(registry: MetricRegistry(metrics: [first, second]))

        coordinator.startObservingAll()

        XCTAssertEqual(first.startObservingCount, 1)
        XCTAssertEqual(second.startObservingCount, 1)
        XCTAssertEqual(coordinator.observedIDs, ["a", "b"])
    }

    func testStartIsIdempotent() {
        let metric = MockAdjustableMetric(id: "a")
        let coordinator = MetricObservationCoordinator(registry: MetricRegistry(metrics: [metric]))

        coordinator.startObservingAll()
        coordinator.startObservingAll()

        XCTAssertEqual(metric.startObservingCount, 1)
        XCTAssertEqual(coordinator.observedIDs, ["a"])
    }

    func testChangeHandlerReceivesMetricIDAndValue() {
        let metric = MockAdjustableMetric(id: "a")
        let coordinator = MetricObservationCoordinator(registry: MetricRegistry(metrics: [metric]))
        var received: [(String, Double)] = []
        coordinator.setChangeHandler { metricID, value in
            received.append((metricID, value))
        }

        coordinator.startObservingAll()
        metric.sendValue(0.42)

        XCTAssertEqual(received.count, 1)
        XCTAssertEqual(received.first?.0, "a")
        XCTAssertEqual(received.first?.1 ?? 0, 0.42, accuracy: 0.0001)
    }

    func testStopAllStopsEveryObservedMetric() {
        let first = MockAdjustableMetric(id: "a")
        let second = MockAdjustableMetric(id: "b")
        let coordinator = MetricObservationCoordinator(registry: MetricRegistry(metrics: [first, second]))

        coordinator.startObservingAll()
        coordinator.stopAll()

        XCTAssertEqual(first.stopObservingCount, 1)
        XCTAssertEqual(second.stopObservingCount, 1)
        XCTAssertTrue(coordinator.observedIDs.isEmpty)
    }

    func testUnavailableMetricIsObservedToo() {
        // 선택 해제된 지표도, 사용 불가 지표도 계속 관측해 availability를 최신으로 유지한다.
        let metric = MockAdjustableMetric(id: "a", availability: .unavailable(reason: "로드 실패"))
        let coordinator = MetricObservationCoordinator(registry: MetricRegistry(metrics: [metric]))

        coordinator.startObservingAll()

        XCTAssertEqual(metric.startObservingCount, 1)
        XCTAssertEqual(coordinator.observedIDs, ["a"])
    }

    func testObservedIDsFollowRegistryOrder() {
        let coordinator = MetricObservationCoordinator(
            registry: MetricRegistry(metrics: [
                MockAdjustableMetric(id: "third"),
                MockAdjustableMetric(id: "first"),
                MockAdjustableMetric(id: "second"),
            ])
        )

        coordinator.startObservingAll()

        XCTAssertEqual(coordinator.observedIDs, ["third", "first", "second"])
    }
}
