import MonitoradCore
import XCTest

/// 설정 규칙: 기본값·표시 시간 클램프·선택 최대/최소·순서.
final class SettingsTests: XCTestCase {
    func testDefaultSettingsFollowSpec() {
        let settings = MonitoradSettings.default
        XCTAssertEqual(settings.selectedMetricIDs, [MetricID.volume, MetricID.displayBrightness])
        XCTAssertEqual(settings.hudDuration, 1.0)
        XCTAssertFalse(settings.launchAtLogin)
        XCTAssertFalse(settings.replacementEnabled)
        XCTAssertEqual(MonitoradSettings.maximumSelectedMetrics, 3)
        XCTAssertEqual(MonitoradSettings.minimumSelectedMetrics, 1)
        XCTAssertEqual(MonitoradSettings.hudDurationRange, 0.5...2.0)
    }

    func testHUDDurationIsClampedIntoRange() {
        XCTAssertEqual(MonitoradSettings.clampedHUDDuration(0.1), 0.5, accuracy: 0.0001)
        XCTAssertEqual(MonitoradSettings.clampedHUDDuration(0.0), 0.5, accuracy: 0.0001)
        XCTAssertEqual(MonitoradSettings.clampedHUDDuration(2.0), 2.0, accuracy: 0.0001)
        XCTAssertEqual(MonitoradSettings.clampedHUDDuration(2.5), 2.0, accuracy: 0.0001)
        XCTAssertEqual(MonitoradSettings.clampedHUDDuration(1.0), 1.0, accuracy: 0.0001)
    }

    func testHUDDurationIsRoundedToTenths() {
        XCTAssertEqual(MonitoradSettings.clampedHUDDuration(0.53), 0.5, accuracy: 0.0001)
        XCTAssertEqual(MonitoradSettings.clampedHUDDuration(0.56), 0.6, accuracy: 0.0001)
        XCTAssertEqual(MonitoradSettings.clampedHUDDuration(1.04), 1.0, accuracy: 0.0001)
        XCTAssertEqual(MonitoradSettings.clampedHUDDuration(1.96), 2.0, accuracy: 0.0001)
    }

    func testHUDDurationFallsBackForNonFiniteValues() {
        XCTAssertEqual(MonitoradSettings.clampedHUDDuration(.nan), MonitoradSettings.defaultHUDDuration)
        XCTAssertEqual(MonitoradSettings.clampedHUDDuration(.infinity), MonitoradSettings.defaultHUDDuration)
    }

    func testSelectionKeepsGivenOrder() {
        let normalized = MonitoradSettings.normalizedSelection(
            ["b", "a", "c"],
            knownMetricIDs: ["a", "b", "c", "d"]
        )
        XCTAssertEqual(normalized, ["b", "a", "c"])
    }

    func testSelectionDeduplicatesPreservingFirstOccurrence() {
        let normalized = MonitoradSettings.normalizedSelection(
            ["b", "a", "b"],
            knownMetricIDs: ["a", "b"]
        )
        XCTAssertEqual(normalized, ["b", "a"])
    }

    func testSelectionIsLimitedToThreeMetrics() {
        let normalized = MonitoradSettings.normalizedSelection(
            ["d", "c", "b", "a"],
            knownMetricIDs: ["a", "b", "c", "d"]
        )
        XCTAssertEqual(normalized, ["d", "c", "b"])
    }

    func testSelectionDropsUnknownMetricIDs() {
        let normalized = MonitoradSettings.normalizedSelection(
            [MetricID.volume, "unknown-metric", MetricID.displayBrightness],
            knownMetricIDs: [MetricID.volume, MetricID.displayBrightness]
        )
        XCTAssertEqual(normalized, [MetricID.volume, MetricID.displayBrightness])
    }

    func testEmptySelectionFallsBackToDefaultMetrics() {
        let normalized = MonitoradSettings.normalizedSelection(
            [],
            knownMetricIDs: [MetricID.volume, MetricID.displayBrightness]
        )
        XCTAssertEqual(normalized, [MetricID.volume, MetricID.displayBrightness])
    }

    func testSelectionFallsBackToRegistryOrderWhenDefaultsAreUnknown() {
        let normalized = MonitoradSettings.normalizedSelection(
            ["unknown"],
            knownMetricIDs: ["custom-a", "custom-b"]
        )
        XCTAssertEqual(normalized, ["custom-a", "custom-b"])
    }

    func testNormalizeAppliesEveryRuleAtOnce() {
        var settings = MonitoradSettings(
            selectedMetricIDs: ["unknown", "b", "b"],
            hudDuration: 9.0,
            launchAtLogin: true,
            replacementEnabled: true
        )
        settings.normalize(knownMetricIDs: ["a", "b"])

        XCTAssertEqual(settings.selectedMetricIDs, ["b"])
        XCTAssertEqual(settings.hudDuration, 2.0)
        XCTAssertTrue(settings.launchAtLogin)
        XCTAssertTrue(settings.replacementEnabled)
    }

    func testSettingsCodableRoundTrip() throws {
        let settings = MonitoradSettings(
            selectedMetricIDs: [MetricID.displayBrightness, MetricID.volume],
            hudDuration: 1.4,
            launchAtLogin: true,
            replacementEnabled: true
        )
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(MonitoradSettings.self, from: data)
        XCTAssertEqual(decoded, settings)
    }
}
