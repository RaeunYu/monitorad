import MonitoradCore
import XCTest

/// Accessibility 권한 안내 노출 규칙과 문구.
final class AccessibilityNoticeTests: XCTestCase {
    func testNoticeIsShownOnlyWhenPermissionIsMissing() {
        XCTAssertTrue(AccessibilityNotice.shouldShow(isTrusted: false))
        XCTAssertFalse(AccessibilityNotice.shouldShow(isTrusted: true))
    }

    func testNoticeMessageMentionsV02Scope() {
        XCTAssertTrue(AccessibilityNotice.message.contains("v0.2"))
        XCTAssertTrue(AccessibilityNotice.message.contains("Accessibility"))
    }
}
