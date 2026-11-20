import Foundation

/// 내장 지표 registry. 지표 추가는 ``register(_:)`` 한 줄이다 (ADR-0002).
public final class MetricRegistry {
    /// 등록 순서대로 보관한 지표. 조회 순서의 기준이 된다.
    public private(set) var metrics: [AdjustableMetric]

    public init(metrics: [AdjustableMetric] = []) {
        self.metrics = []
        for metric in metrics {
            register(metric)
        }
    }

    /// 등록된 지표 식별자 목록. 등록 순서를 유지한다.
    public var ids: [String] {
        metrics.map(\.id)
    }

    /// 식별자로 지표를 찾는다. 없으면 nil.
    public func metric(id: String) -> AdjustableMetric? {
        metrics.first { $0.id == id }
    }

    /// 지표를 등록한다. 같은 식별자가 이미 있으면 아무것도 하지 않고 false를 반환한다.
    @discardableResult
    public func register(_ metric: AdjustableMetric) -> Bool {
        guard !ids.contains(metric.id) else { return false }
        metrics.append(metric)
        return true
    }

    /// 선택된 식별자를 설정 순서대로 지표로 변환한다. 없는 식별자는 건너뛴다.
    public func resolveAll(selectedIDs: [String]) -> [AdjustableMetric] {
        selectedIDs.compactMap { metric(id: $0) }
    }

    /// 선택된 식별자 중 지금 사용 가능한 지표만 설정 순서대로 반환한다.
    /// 메뉴바 인디케이터는 이 목록만 표시한다.
    public func resolveDisplayMetrics(selectedIDs: [String]) -> [AdjustableMetric] {
        resolveAll(selectedIDs: selectedIDs).filter { $0.availability.isAvailable }
    }

    /// v0.1 내장 지표 목록. 새 지표는 구현체를 만든 뒤 여기에 추가한다.
    public static func builtInMetrics() -> [AdjustableMetric] {
        [
            SystemVolumeMetric(), // 볼륨 (CoreAudio, public)
            DisplayBrightnessMetric(), // 디스플레이 밝기 (DisplayServices, private)
        ]
    }

    /// registry 생성. 기본값은 내장 지표 목록이며, 테스트는 mock 목록을 주입해
    /// 실제 어댑터 생성 없이 등록·순서·중복 규칙을 검증한다.
    public static func makeDefault(metrics: [AdjustableMetric]? = nil) -> MetricRegistry {
        MetricRegistry(metrics: metrics ?? builtInMetrics())
    }
}
