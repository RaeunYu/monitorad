import Foundation

/// registry의 모든 지표를 관측한다.
///
/// 관측 여부를 선택 목록에 묶으면 해제된 지표의 availability가 갱신되지 않는다(verifier P3).
/// 그래서 registry에 등록된 지표는 전부 관측하고, 화면 표시만 선택 목록으로 제한한다.
/// 관측 시작·중지는 중복 호출에 안전하다.
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

    /// 변경 콜백을 등록한다. (지표 식별자, 새 값)으로 호출된다.
    public func setChangeHandler(_ handler: ((String, Double) -> Void)?) {
        changeHandler = handler
    }

    /// registry의 모든 지표 관측을 시작한다. 이미 관측 중인 지표는 건너뛴다.
    /// 선택 목록은 폴링 주기 조정(``AdjustableMetricCadence``)에만 쓰인다.
    public func startObservingAll(selectedMetricIDs: [String]) {
        let selected = Set(selectedMetricIDs)
        for metric in registry.metrics where !observedMetricIDs.contains(metric.id) {
            (metric as? AdjustableMetricCadence)?.updatePollingSelection(isSelected: selected.contains(metric.id))
            // 콜백이 지표를 강하게 붙잡지 않도록 식별자만 캡처한다.
            let metricID = metric.id
            metric.onChange = { [weak self] value in
                self?.changeHandler?(metricID, value)
            }
            metric.startObserving()
            observedMetricIDs.insert(metric.id)
        }
    }

    /// 선택 목록 변경을 폴링 주기 조정 지표에 반영한다. 관측은 계속 유지한다.
    public func updateSelectedMetricIDs(_ selectedMetricIDs: [String]) {
        let selected = Set(selectedMetricIDs)
        for metric in registry.metrics {
            (metric as? AdjustableMetricCadence)?.updatePollingSelection(isSelected: selected.contains(metric.id))
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
