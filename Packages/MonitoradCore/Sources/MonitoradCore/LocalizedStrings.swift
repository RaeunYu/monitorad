import Foundation

/// Core의 사용자 노출 문구를 키 기반으로 로컬라이즈한다.
///
/// 앱 번들의 `ko.lproj/Localizable.strings`에서 키를 찾고, 리소스가 없는 환경
/// (단위 테스트 러너 등)에서는 한국어 기본값으로 폴백한다.
enum LocalizedStrings {
    static func localized(_ key: String, fallback: String) -> String {
        let value = String(localized: String.LocalizationValue(key))
        return value == key ? fallback : value
    }
}
