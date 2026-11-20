import MonitoradCore
import XCTest

/// 레이아웃 선택: 1개 → 큰 링, 2~3개 → 작은 링 나란히, 그 밖 → nil.
final class IndicatorLayoutTests: XCTestCase {
    func testSingleMetricUsesLargeRing() {
        let layout = try? XCTUnwrap(IndicatorLayout.resolve(metricCount: 1))
        XCTAssertEqual(layout?.ringSize, .large)
        XCTAssertEqual(layout?.ringDiameter, IndicatorLayout.largeRingDiameter)
        XCTAssertEqual(layout?.ringSpacing, 0)
        XCTAssertEqual(layout?.metricCount, 1)
    }

    func testTwoMetricsUseSmallRingsSideBySide() {
        let layout = try? XCTUnwrap(IndicatorLayout.resolve(metricCount: 2))
        XCTAssertEqual(layout?.ringSize, .small)
        XCTAssertEqual(layout?.ringDiameter, IndicatorLayout.smallRingDiameter)
        XCTAssertEqual(layout?.ringSpacing, IndicatorLayout.smallRingSpacing)
        XCTAssertGreaterThan(layout?.ringSpacing ?? 0, 0)
    }

    func testThreeMetricsUseSmallRingsSideBySide() {
        let layout = try? XCTUnwrap(IndicatorLayout.resolve(metricCount: 3))
        XCTAssertEqual(layout?.ringSize, .small)
        XCTAssertEqual(layout?.metricCount, 3)
        XCTAssertEqual(layout?.height, IndicatorLayout.height)
    }

    func testMoreMetricsWidenTheItem() {
        let one = IndicatorLayout.resolve(metricCount: 1)!
        let two = IndicatorLayout.resolve(metricCount: 2)!
        let three = IndicatorLayout.resolve(metricCount: 3)!

        XCTAssertLessThan(one.itemWidth, two.itemWidth)
        XCTAssertLessThan(two.itemWidth, three.itemWidth)
    }

    func testItemWidthIsInsetsPlusDiametersPlusSpacing() {
        let one = IndicatorLayout.resolve(metricCount: 1)!
        XCTAssertEqual(one.itemWidth, 3 + 20 + 3, accuracy: 0.0001)

        let two = IndicatorLayout.resolve(metricCount: 2)!
        XCTAssertEqual(two.itemWidth, 3 + 15 + 2 + 15 + 3, accuracy: 0.0001)

        let three = IndicatorLayout.resolve(metricCount: 3)!
        XCTAssertEqual(three.itemWidth, 3 + 15 + 2 + 15 + 2 + 15 + 3, accuracy: 0.0001)
    }

    func testZeroOrTooManyMetricsHaveNoLayout() {
        XCTAssertNil(IndicatorLayout.resolve(metricCount: 0))
        XCTAssertNil(IndicatorLayout.resolve(metricCount: 4))
        XCTAssertNil(IndicatorLayout.resolve(metricCount: -1))
    }

    func testLargeRingIsLargerThanSmallRing() {
        XCTAssertGreaterThan(IndicatorLayout.largeRingDiameter, IndicatorLayout.smallRingDiameter)
        XCTAssertEqual(IndicatorLayout.maximumMetricCount, 3)
    }
}
