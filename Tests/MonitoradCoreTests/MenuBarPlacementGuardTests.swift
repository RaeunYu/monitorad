import CoreGraphics
import MonitoradCore
import XCTest

/// status item이 화면 밖으로 밀렸을 때의 재추가 판정.
final class MenuBarPlacementGuardTests: XCTestCase {
    /// 일반적인 메뉴바 위치: 화면 우상단 안쪽.
    private let screenFrame = CGRect(x: 0, y: 0, width: 1512, height: 982)

    func testNormalMenuBarFrameNeedsNoReinstall() {
        let itemFrame = CGRect(x: 1200, y: 960, width: 34, height: 22)
        XCTAssertFalse(
            MenuBarPlacementGuard.shouldReinstall(
                itemFrame: itemFrame,
                screenFrames: [screenFrame],
                isWindowVisible: true
            )
        )
    }

    func testOffscreenFrameTriggersReinstall() {
        // Tahoe에서 보고된 `(0, -17, 34×22)` 프레임.
        let itemFrame = CGRect(x: 0, y: -17, width: 34, height: 22)
        XCTAssertTrue(
            MenuBarPlacementGuard.shouldReinstall(
                itemFrame: itemFrame,
                screenFrames: [screenFrame],
                isWindowVisible: true
            )
        )
    }

    func testInvisibleWindowTriggersReinstall() {
        let itemFrame = CGRect(x: 1200, y: 960, width: 34, height: 22)
        XCTAssertTrue(
            MenuBarPlacementGuard.shouldReinstall(
                itemFrame: itemFrame,
                screenFrames: [screenFrame],
                isWindowVisible: false
            )
        )
    }

    func testZeroSizedFrameTriggersReinstall() {
        XCTAssertTrue(
            MenuBarPlacementGuard.shouldReinstall(
                itemFrame: .zero,
                screenFrames: [screenFrame],
                isWindowVisible: true
            )
        )
    }

    func testFrameMostlyOutsideScreenTriggersReinstall() {
        let itemFrame = CGRect(x: 1500, y: 960, width: 34, height: 22)
        XCTAssertTrue(
            MenuBarPlacementGuard.shouldReinstall(
                itemFrame: itemFrame,
                screenFrames: [screenFrame],
                isWindowVisible: true
            )
        )
    }

    func testMultipleScreensKeepItemWhenVisibleOnAnyScreen() {
        let secondScreen = CGRect(x: 1512, y: 0, width: 1920, height: 1080)
        let itemFrame = CGRect(x: 1600, y: 1000, width: 34, height: 22)
        XCTAssertFalse(
            MenuBarPlacementGuard.shouldReinstall(
                itemFrame: itemFrame,
                screenFrames: [screenFrame, secondScreen],
                isWindowVisible: true
            )
        )
    }

    func testNoScreensDoesNotCauseReinstallLoop() {
        XCTAssertFalse(
            MenuBarPlacementGuard.shouldReinstall(
                itemFrame: CGRect(x: 0, y: 0, width: 34, height: 22),
                screenFrames: [],
                isWindowVisible: true
            )
        )
    }

    func testReinstallAttemptsAreBounded() {
        XCTAssertEqual(MenuBarPlacementGuard.maximumReinstallAttempts, 3)
    }
}
