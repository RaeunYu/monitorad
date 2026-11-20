import ApplicationServices
import Foundation

/// Accessibility 권한 조회와 시스템 설정 링크.
enum AccessibilityPermission {
    /// 키 가로채기에 필요한 Accessibility 권한이 현재 앱에 있는지.
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// 시스템 설정 ▸ 개인정보 보호 및 보안 ▸ 손쉬운 사용 패널.
    static let settingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    )!
}
