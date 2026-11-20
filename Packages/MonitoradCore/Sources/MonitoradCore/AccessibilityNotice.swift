import Foundation

/// Accessibility 권한 안내 문구와 노출 규칙.
public enum AccessibilityNotice {
    /// 팝오버의 안내 행 문구. 키 가로채기는 v0.2 범위임을 함께 알린다.
    public static let message = "키 가로채기에는 Accessibility 권한이 필요합니다. (v0.2에서 키 가로채기 도입 예정)"

    /// 권한이 없을 때만 안내 행을 노출한다. 권한이 있으면 숨긴다.
    public static func shouldShow(isTrusted: Bool) -> Bool {
        !isTrusted
    }
}
