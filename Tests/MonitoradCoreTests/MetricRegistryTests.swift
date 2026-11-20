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

    func testMakeDefaultRegistersInjectedMetricsInOrder() {
        let first = MockAdjustableMetric(id: "first")
        let second = MockAdjustableMetric(id: "second")
        let registry = MetricRegistry.makeDefault(metrics: [first, second])

        XCTAssertEqual(registry.ids, ["first", "second"])
        XCTAssertTrue(registry.metric(id: "first") === first)
        XCTAssertTrue(registry.metric(id: "second") === second)
    }

    func testMakeDefaultIgnoresDuplicateMetricIdentifiers() {
        let first = MockAdjustableMetric(id: "first")
        let duplicate = MockAdjustableMetric(id: "first")
        let registry = MetricRegistry.makeDefault(metrics: [first, duplicate])

        XCTAssertEqual(registry.ids, ["first"])
        XCTAssertTrue(registry.metric(id: "first") === first)
    }

    func testBuiltInMetricIDsAreStable() {
        // 설정에 저장되는 식별자이므로 바뀌면 안 된다.
        XCTAssertEqual(MetricID.builtIn, [MetricID.volume, MetricID.displayBrightness])
    }

    func testNewMetricNeedsOnlyOneRegistrationLine() {
        let registry = MetricRegistry.makeDefault(metrics: [MockAdjustableMetric(id: "existing")])
        let mock = MockAdjustableMetric(id: "mock-metric", displayName: "목업")
        XCTAssertTrue(registry.register(mock))

        let resolved = registry.resolveDisplayMetrics(selectedIDs: ["mock-metric"])
        XCTAssertEqual(resolved.map(\.id), ["mock-metric"])
    }
}
