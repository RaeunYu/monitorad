import CoreGraphics
import MonitoradCore
import XCTest

/// 밝기 대상 디스플레이 선택 (P2).
/// 메인 디스플레이가 외장 모니터여도 활성 내장 디스플레이가 있으면 내장을 골라야 한다.
final class BuiltInDisplaySelectionTests: XCTestCase {
    func testSingleBuiltInDisplayIsSelected() {
        let selected = BuiltInDisplaySelection.preferredDisplayID(
            activeDisplayIDs: [42],
            builtInDisplayIDs: [42]
        )
        XCTAssertEqual(selected, 42)
    }

    func testBuiltInIsSelectedWhenExternalMonitorIsMain() {
        // 활성 목록의 첫 항목(외장·메인)이 아니라 내장(42)을 골라야 한다.
        let selected = BuiltInDisplaySelection.preferredDisplayID(
            activeDisplayIDs: [7, 42],
            builtInDisplayIDs: [42]
        )
        XCTAssertEqual(selected, 42)
    }

    func testExternalOnlyEnvironmentReturnsNil() {
        // clamshell: 내장 디스플레이가 비활성이라 밝기를 읽을 수 없다.
        let selected = BuiltInDisplaySelection.preferredDisplayID(
            activeDisplayIDs: [7],
            builtInDisplayIDs: []
        )
        XCTAssertNil(selected)
    }

    func testEmptyActiveDisplayListReturnsNil() {
        let selected = BuiltInDisplaySelection.preferredDisplayID(
            activeDisplayIDs: [],
            builtInDisplayIDs: [42]
        )
        XCTAssertNil(selected)
    }

    func testFirstBuiltInDisplayInActiveOrderIsSelected() {
        let selected = BuiltInDisplaySelection.preferredDisplayID(
            activeDisplayIDs: [5, 4, 3],
            builtInDisplayIDs: [3, 4]
        )
        XCTAssertEqual(selected, 4)
    }
}
