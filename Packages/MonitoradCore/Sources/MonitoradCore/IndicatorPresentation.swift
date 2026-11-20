import Foundation

/// 메뉴바 인디케이터에 그릴 링 하나(표시 모델).
/// Core는 SwiftUI에 의존하지 않으므로 색은 ``MetricColor``로 둔다.
public struct RingModel: Identifiable, Equatable {
    /// 지표 식별자.
    public let id: String
    /// 접근성 라벨에 쓰는 표시명.
    public let name: String
    /// 0...1로 정규화된 값.
    public let value: Double
    /// 링 색.
    public let tint: MetricColor
    /// 링 가운데 아이콘(SF Symbol 이름).
    public let symbolName: String

    public init(id: String, name: String, value: Double, tint: MetricColor, symbolName: String) {
        self.id = id
        self.name = name
        self.value = value
        self.tint = tint
        self.symbolName = symbolName
    }
}

/// 선택된 지표 목록을 메뉴바 인디케이터 표시 상태로 변환한 결과.
///
/// 순수 경계다. 선택·가용성·값·레이아웃 규칙을 Core에서 한 번에 계산해
/// UI는 이 결과(rings/layout/placeholderReason)만 소비한다.
public struct IndicatorPresentation: Equatable {
    /// 링 배치. 링이 0개면 nil(placeholder).
    public let layout: IndicatorLayout?
    /// 표시할 링 목록(선택 순서 유지, 표시 불가 지표 제외).
    public let rings: [RingModel]
    /// 표시할 지표가 없을 때 placeholder와 함께 보여 줄 사유.
    public let placeholderReason: String?

    public init(layout: IndicatorLayout?, rings: [RingModel], placeholderReason: String?) {
        self.layout = layout
        self.rings = rings
        self.placeholderReason = placeholderReason
    }

    /// 선택된 지표 목록(설정 순서)을 인디케이터 표시 상태로 변환한다.
    /// 사용 불가 지표는 링에서 제외하고, 전부 제외되면 placeholder 사유를 채운다.
    public static func resolve(selectedMetrics: [AdjustableMetric]) -> IndicatorPresentation {
        let displayableMetrics = selectedMetrics.filter { $0.availability.isAvailable }
        let rings = displayableMetrics.map { metric in
            RingModel(
                id: metric.id,
                name: metric.displayName,
                value: min(max(metric.value, 0), 1),
                tint: metric.tint,
                symbolName: metric.symbolName
            )
        }
        let layout = IndicatorLayout.resolve(metricCount: rings.count)
        let placeholderReason = rings.isEmpty
            ? IndicatorEmptyState.message(for: selectedMetrics)
            : nil
        return IndicatorPresentation(layout: layout, rings: rings, placeholderReason: placeholderReason)
    }
}
