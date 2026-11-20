import Foundation

/// 메뉴바 인디케이터에 표시할 수 있는 지표가 하나도 없을 때 보여 줄 안내 문구.
///
/// 선택 규칙(최소 1개)은 유지하면서, 선택된 지표가 전부 사용 불가가 되면 링이 0개가 된다.
/// 이때 인디케이터는 placeholder를 그리고 사용 불가 사유를 함께 노출한다.
public enum IndicatorEmptyState {
    /// 사용 불가 사유가 없을 때의 기본 문구.
    public static let defaultMessage = "표시할 수 있는 지표가 없습니다"

    /// 지표들의 사용 불가 사유를 모아 안내 문구를 만든다. 중복 사유는 한 번만 넣는다.
    /// 사용 가능한 지표만 있거나 목록이 비어 있으면 기본 문구를 반환한다.
    public static func message(for metrics: [AdjustableMetric]) -> String {
        var reasons: [String] = []
        for metric in metrics {
            guard let reason = metric.availability.unavailableReason else { continue }
            if !reasons.contains(reason) {
                reasons.append(reason)
            }
        }
        guard !reasons.isEmpty else { return defaultMessage }
        return reasons.joined(separator: " ")
    }
}
