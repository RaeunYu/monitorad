import Foundation

/// 내장 지표의 식별자. 설정(UserDefaults)에 저장되므로 문자열을 바꾸면 사용자 설정이 초기화된다.
public enum MetricID {
    /// 시스템 출력 볼륨 (CoreAudio).
    public static let volume = "volume"

    /// 디스플레이 밝기 (DisplayServices, private).
    public static let displayBrightness = "display-brightness"

    /// v0.1에 내장된 지표의 기본 순서.
    public static let builtIn: [String] = [volume, displayBrightness]
}
