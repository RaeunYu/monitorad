import MonitoradCore
import XCTest

/// UserDefaults 저장/복원과 읽기·쓰기 시 규칙 보정.
final class SettingsStoreTests: XCTestCase {
    private let suiteName = "MonitoradCoreTests.SettingsStore"
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testStartsWithDefaultsWhenStorageIsEmpty() {
        let store = SettingsStore(
            defaults: defaults,
            knownMetricIDs: [MetricID.volume, MetricID.displayBrightness]
        )
        XCTAssertEqual(store.settings, MonitoradSettings.default)
    }

    func testPersistsAndReloadsSettings() {
        let store = SettingsStore(
            defaults: defaults,
            knownMetricIDs: [MetricID.volume, MetricID.displayBrightness]
        )
        store.update(
            MonitoradSettings(
                selectedMetricIDs: [MetricID.displayBrightness],
                hudDuration: 1.7,
                launchAtLogin: true,
                replacementEnabled: true
            )
        )

        let reloaded = SettingsStore(
            defaults: defaults,
            knownMetricIDs: [MetricID.volume, MetricID.displayBrightness]
        )
        XCTAssertEqual(reloaded.settings.selectedMetricIDs, [MetricID.displayBrightness])
        XCTAssertEqual(reloaded.settings.hudDuration, 1.7, accuracy: 0.0001)
        XCTAssertTrue(reloaded.settings.launchAtLogin)
        XCTAssertTrue(reloaded.settings.replacementEnabled)
    }

    func testStoredValuesAreNormalizedWhenRead() throws {
        let raw = MonitoradSettings(
            selectedMetricIDs: ["unknown", MetricID.volume, MetricID.volume],
            hudDuration: 7.5
        )
        defaults.set(try JSONEncoder().encode(raw), forKey: SettingsStore.defaultsKey)

        let store = SettingsStore(
            defaults: defaults,
            knownMetricIDs: [MetricID.volume, MetricID.displayBrightness]
        )
        XCTAssertEqual(store.settings.selectedMetricIDs, [MetricID.volume])
        XCTAssertEqual(store.settings.hudDuration, 2.0, accuracy: 0.0001)
    }

    func testUpdateNormalizesBeforeSaving() {
        let store = SettingsStore(
            defaults: defaults,
            knownMetricIDs: [MetricID.volume, MetricID.displayBrightness]
        )
        store.update(
            MonitoradSettings(
                selectedMetricIDs: ["a", "b", "c", "d"],
                hudDuration: 0.02
            )
        )
        XCTAssertEqual(store.settings.selectedMetricIDs, [MetricID.volume, MetricID.displayBrightness])
        XCTAssertEqual(store.settings.hudDuration, 0.5, accuracy: 0.0001)
    }

    func testMutatePersistsChanges() {
        let store = SettingsStore(
            defaults: defaults,
            knownMetricIDs: [MetricID.volume, MetricID.displayBrightness]
        )
        store.mutate { settings in
            settings.hudDuration = 1.3
            settings.replacementEnabled = true
        }

        let reloaded = SettingsStore(
            defaults: defaults,
            knownMetricIDs: [MetricID.volume, MetricID.displayBrightness]
        )
        XCTAssertEqual(reloaded.settings.hudDuration, 1.3, accuracy: 0.0001)
        XCTAssertTrue(reloaded.settings.replacementEnabled)
    }
}
