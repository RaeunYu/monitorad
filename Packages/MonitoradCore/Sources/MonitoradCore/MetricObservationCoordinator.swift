import Foundation

/// 선택 상태에 맞춰 지표들의 관측 시작·중지를 관리한다.
/// 선택에서 빠진 지표는 관측을 멈추고, 새로 선택된 지표는 관측을 시작한다.
/// 변경 콜백은 (지표 식별자, 새 값)으로 앱에 전달된다.
public final class MetricObservationCoordinator {
    private let registry: MetricRegistry
    private var observedMetricIDs: Set<String> = []
    private var changeHandler: ((String, Double) -> Void)?

    public init(registry: MetricRegistry) {
        self.registry = registry
    }

    /// 현재 관측 중인 지표 식별자. registry 등록 순서를 유지한다.
    public var observedIDs: [String] {
        registry.metrics.map(\.id).filter { observedMetricIDs.contains($0) }
    }

    /// 변경 콜백을 등록한다.
    public func setChangeHandler(_ handler: ((String, Double) -> Void)?) {
        changeHandler = handler
    }

    /// 선택 목록에 맞게 관측 상태를 맞춘다. 이미 맞으면 아무것도 하지 않는다.
    public func observe(metricIDs: [String]) {
        let wanted = Set(metricIDs)
        for metric in registry.metrics {
            let shouldObserve = wanted.contains(metric.id)
            if shouldObserve, !observedMetricIDs.contains(metric.id) {
                // 콜백이 지표를 강하게 붙잡지 않도록 식별자만 캡처한다.
                let metricID = metric.id
                metric.onChange = { [weak self] value in
                    self?.changeHandler?(metricID, value)
                }
                metric.startObserving()
                observedMetricIDs.insert(metric.id)
            } else if !shouldObserve, observedMetricIDs.contains(metric.id) {
                metric.stopObserving()
                metric.onChange = nil
                observedMetricIDs.remove(metric.id)
            }
        }
    }

    /// 모든 관측을 중지한다. 앱 종료 시 호출한다.
    public func stopAll() {
        for metric in registry.metrics where observedMetricIDs.contains(metric.id) {
            metric.stopObserving()
            metric.onChange = nil
        }
        observedMetricIDs.removeAll()
    }
}
