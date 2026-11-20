import MonitoradCore
import XCTest

/// registry 조회·순서·중복·미지원 지표 처리.
final class MetricRegistryTests: XCTestCase {
    func testRegisterAndLookupByID() {
        let registry = MetricRegistry()
        let metric = MockAdjustableMetric(id: "volume")
        XCTAssertTrue(registry.register(metric))

        XCTAssertEqual(registry.ids, ["volume"])
        XCTAssertTrue(registry.metric(id: "volume") === metric)
        XCTAssertNil(registry.metric(id: "missing"))
    }

    func testRegisterRejectsDuplicateIdentifier() {
        let registry = MetricRegistry()
        let first = MockAdjustableMetric(id: "volume")
        let second = MockAdjustableMetric(id: "volume")

        XCTAssertTrue(registry.register(first))
        XCTAssertFalse(registry.register(second))
        XCTAssertEqual(registry.ids, ["volume"])
        XCTAssertTrue(registry.metric(id: "volume") === first)
    }

    func testResolveAllFollowsSelectionOrder() {
        let first = MockAdjustableMetric(id: "a")
        let second = MockAdjustableMetric(id: "b")
        let third = MockAdjustableMetric(id: "c")
        let registry = MetricRegistry(metrics: [first, second, third])

        let resolved = registry.resolveAll(selectedIDs: ["c", "a"])
        XCTAssertEqual(resolved.map(\.id), ["c", "a"])
    }

    func testResolveAllSkipsUnknownIdentifiers() {
        let registry = MetricRegistry(metrics: [MockAdjustableMetric(id: "a")])
        let resolved = registry.resolveAll(selectedIDs: ["missing", "a"])
        XCTAssertEqual(resolved.map(\.id), ["a"])
    }

    func testResolveDisplayMetricsExcludesUnavailableMetrics() {
        let available = MockAdjustableMetric(id: "available")
        let unavailable = MockAdjustableMetric(
            id: "unavailable",
            availability: .unavailable(reason: "내장 디스플레이가 없습니다")
        )
        let registry = MetricRegistry(metrics: [available, unavailable])

        let resolved = registry.resolveDisplayMetrics(selectedIDs: ["unavailable", "available"])
        XCTAssertEqual(resolved.map(\.id), ["available"])
    }

    func testResolveDisplayMetricsKeepsEmptyResultWhenNothingIsAvailable() {
        let unavailable = MockAdjustableMetric(
            id: "only",
            availability: .unavailable(reason: "로드 실패")
        )
        let registry = MetricRegistry(metrics: [unavailable])
        XCTAssertTrue(registry.resolveDisplayMetrics(selectedIDs: ["only"]).isEmpty)
    }

    func testMakeDefaultRegistersBuiltInMetrics() {
        let registry = MetricRegistry.makeDefault()
        XCTAssertEqual(registry.ids, [MetricID.volume, MetricID.displayBrightness])
        XCTAssertNotNil(registry.metric(id: MetricID.volume))
        XCTAssertNotNil(registry.metric(id: MetricID.displayBrightness))
    }

    func testNewMetricNeedsOnlyOneRegistrationLine() {
        let registry = MetricRegistry.makeDefault()
        let mock = MockAdjustableMetric(id: "mock-metric", displayName: "목업")
        XCTAssertTrue(registry.register(mock))

        let resolved = registry.resolveDisplayMetrics(selectedIDs: ["mock-metric"])
        XCTAssertEqual(resolved.map(\.id), ["mock-metric"])
    }
}
