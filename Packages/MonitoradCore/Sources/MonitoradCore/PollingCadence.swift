import Foundation

/// 선택 여부에 따른 관측 주기(초) 결정.
///
/// 밝기처럼 변경 알림이 없어 폴링이 필요한 지표는 표시 중일 때만 촘촘히 읽고,
/// 표시되지 않는 동안에는 느리게 읽어 비용을 줄인다.
public struct PollingCadence: Equatable {
    /// 표시 중일 때의 관측 주기(초).
    public let selectedInterval: TimeInterval
    /// 표시되지 않을 때의 관측 주기(초).
    public let idleInterval: TimeInterval

    public init(selectedInterval: TimeInterval, idleInterval: TimeInterval) {
        self.selectedInterval = selectedInterval
        self.idleInterval = idleInterval
    }

    /// 내장 밝기 기본 주기: 선택 0.5초, 미선택 2초.
    public static let brightness = PollingCadence(selectedInterval: 0.5, idleInterval: 2.0)

    /// 선택 상태에 맞는 관측 주기.
    public func interval(isSelected: Bool) -> TimeInterval {
        isSelected ? selectedInterval : idleInterval
    }
}

/// 선택 여부에 따라 관측 주기를 조정할 수 있는 지표.
/// ``MetricObservationCoordinator``가 관측 시작·선택 변경 시 호출한다.
public protocol AdjustableMetricCadence: AnyObject {
    /// 표시 대상 여부가 바뀌었을 때 호출된다. 구현체는 관측 주기를 조정할 수 있다.
    func updatePollingSelection(isSelected: Bool)
}
