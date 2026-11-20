import Foundation

/// 팝오버에서 지표를 선택·해제·재정렬할 때 지키는 규칙 (ADR-0003: 최대 3개, 최소 1개).
public enum MetricSelectionPolicy {
    /// 아직 선택되지 않은 지표를 새로 선택할 수 있는지.
    /// registry에 없거나 이미 선택된 지표, 이미 3개를 선택한 경우는 false다.
    public static func canSelect(_ metricID: String, selectedIDs: [String], knownMetricIDs: [String]) -> Bool {
        guard knownMetricIDs.contains(metricID) else { return false }
        guard !selectedIDs.contains(metricID) else { return false }
        return selectedIDs.count < MonitoradSettings.maximumSelectedMetrics
    }

    /// 선택된 지표를 해제할 수 있는지. 최소 1개는 항상 남는다.
    public static func canDeselect(_ metricID: String, selectedIDs: [String]) -> Bool {
        selectedIDs.contains(metricID) && selectedIDs.count > MonitoradSettings.minimumSelectedMetrics
    }

    /// 체크 토글 결과를 반환한다. 규칙을 위반하면 원래 목록을 그대로 반환한다.
    public static func toggling(_ metricID: String, selectedIDs: [String], knownMetricIDs: [String]) -> [String] {
        if selectedIDs.contains(metricID) {
            guard canDeselect(metricID, selectedIDs: selectedIDs) else { return selectedIDs }
            return selectedIDs.filter { $0 != metricID }
        }
        guard canSelect(metricID, selectedIDs: selectedIDs, knownMetricIDs: knownMetricIDs) else {
            return selectedIDs
        }
        return selectedIDs + [metricID]
    }

    /// 선택된 목록에서 `metricID`를 `targetID` 앞으로 옮긴다.
    /// - `targetID`가 nil이면 맨 뒤로 보낸다.
    /// - 옮길 지표가 없거나 자기 자신 앞으로 옮기는 요청은 순서를 바꾸지 않는다(no-op).
    public static func moving(_ metricID: String, before targetID: String?, selectedIDs: [String]) -> [String] {
        guard let fromIndex = selectedIDs.firstIndex(of: metricID) else { return selectedIDs }
        if metricID == targetID { return selectedIDs }
        var result = selectedIDs
        result.remove(at: fromIndex)
        let targetIndex = targetID.flatMap { result.firstIndex(of: $0) } ?? result.endIndex
        result.insert(metricID, at: min(targetIndex, result.endIndex))
        return result
    }

    /// 팝오버 행에 보여 줄 비활성 사유. 선택 가능하면 nil.
    public static func selectionDisabledReason(
        _ metricID: String,
        selectedIDs: [String],
        knownMetricIDs: [String]
    ) -> String? {
        if selectedIDs.contains(metricID) {
            return canDeselect(metricID, selectedIDs: selectedIDs) ? nil : "최소 1개는 표시해야 합니다"
        }
        guard knownMetricIDs.contains(metricID) else { return "지원하지 않는 지표입니다" }
        if selectedIDs.count >= MonitoradSettings.maximumSelectedMetrics {
            return "최대 3개까지 표시할 수 있습니다"
        }
        return nil
    }
}
