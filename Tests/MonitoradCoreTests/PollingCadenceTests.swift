import MonitoradCore
import XCTest

/// 관측 주기 결정 규칙.
final class PollingCadenceTests: XCTestCase {
    func testBrightnessDefaultCadence() {
        XCTAssertEqual(PollingCadence.brightness.selectedInterval, 0.5, accuracy: 0.0001)
        XCTAssertEqual(PollingCadence.brightness.idleInterval, 2.0, accuracy: 0.0001)
        XCTAssertEqual(PollingCadence.brightness.interval(isSelected: true), 0.5, accuracy: 0.0001)
        XCTAssertEqual(PollingCadence.brightness.interval(isSelected: false), 2.0, accuracy: 0.0001)
    }

    func testCustomCadenceInterval() {
        let cadence = PollingCadence(selectedInterval: 0.25, idleInterval: 3.0)

        XCTAssertEqual(cadence.interval(isSelected: true), 0.25, accuracy: 0.0001)
        XCTAssertEqual(cadence.interval(isSelected: false), 3.0, accuracy: 0.0001)
    }
}
