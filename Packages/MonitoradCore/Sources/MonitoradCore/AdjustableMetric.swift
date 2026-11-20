import Foundation

/// 메뉴바 인디케이터와 (v0.2의) HUD가 공통으로 소비하는 조작 지표의 경계.
///
/// ADR-0002: 새 지표는 이 프로토콜 구현체 하나와 ``MetricRegistry`` 등록 한 줄로 추가한다.
/// 구현체는 모든 프로퍼티와 메서드를 메인 스레드에서만 접근한다.
public protocol AdjustableMetric: AnyObject {
    /// 레지스트리에서 지표를 식별하는 안정적인 문자열. 설정에 저장되므로 바꾸지 않는다.
    var id: String { get }

    /// 팝오버와 접근성 설명에 쓰는 표시명.
    var displayName: String { get }

    /// 지표별 아이콘으로 쓰는 SF Symbol 이름.
    var symbolName: String { get }

    /// 지표별 링 색.
    var tint: MetricColor { get }

    /// 정규화된 현재 값. 항상 0...1 범위다.
    var value: Double { get }

    /// 지금 값을 읽을 수 있는지와, 읽을 수 없을 때의 사유.
    var availability: MetricAvailability { get }

    /// 값 또는 사용 가능 여부가 바뀌었을 때 호출되는 콜백. 값과 함께 호출된다.
    var onChange: ((Double) -> Void)? { get set }

    /// 관측 시작. 중복 호출에 안전해야 한다.
    func startObserving()

    /// 관측 중지. 중복 호출에 안전해야 한다. 다시 시작하면 새로 읽는다.
    func stopObserving()
}
