import Foundation

/// UserDefaults에 Codable로 저장되는 앱 설정.
///
/// 규칙(이슈 #2 수용 기준):
/// - 표시 지표 선택: 최대 3개, 최소 1개, 선택 순서가 표시 순서다.
/// - HUD 표시 시간: 0.5...2.0초, 기본 1.0초, 0.1초 단위로 클램프한다.
/// - 로그인 시 시작·HUD 대체 토글: 기본 false.
public struct MonitoradSettings: Codable, Equatable {
    /// 한 번에 표시할 수 있는 최대 지표 수 (ADR-0003).
    public static let maximumSelectedMetrics = 3

    /// 항상 표시해야 하는 최소 지표 수.
    public static let minimumSelectedMetrics = 1

    /// HUD 표시 시간 허용 범위.
    public static let hudDurationRange: ClosedRange<Double> = 0.5...2.0

    /// HUD 표시 시간 기본값.
    public static let defaultHUDDuration: Double = 1.0

    /// 최초 실행 시 선택되는 지표. registry에 없으면 조용히 걸러진다.
    public static let defaultSelectedMetricIDs: [String] = MetricID.builtIn

    /// 표시할 지표 식별자. 배열 순서가 곧 메뉴바 표시 순서다.
    public var selectedMetricIDs: [String]

    /// HUD 표시 시간(초). v0.1에서는 저장만 하고 v0.2 HUD가 소비한다.
    public var hudDuration: Double

    /// 로그인 시 시작 여부. 실제 상태는 SMAppService가 기준이며 앱이 시작 시 보정한다.
    public var launchAtLogin: Bool

    /// HUD 대체(replacement 모드) 토글. v0.1에서는 저장만 한다.
    public var replacementEnabled: Bool

    public init(
        selectedMetricIDs: [String] = MonitoradSettings.defaultSelectedMetricIDs,
        hudDuration: Double = MonitoradSettings.defaultHUDDuration,
        launchAtLogin: Bool = false,
        replacementEnabled: Bool = false
    ) {
        self.selectedMetricIDs = selectedMetricIDs
        self.hudDuration = hudDuration
        self.launchAtLogin = launchAtLogin
        self.replacementEnabled = replacementEnabled
    }

    public static var `default`: MonitoradSettings {
        MonitoradSettings()
    }

    /// 모든 규칙을 적용한 사본을 반환한다.
    public func normalized(knownMetricIDs: [String]) -> MonitoradSettings {
        var copy = self
        copy.normalize(knownMetricIDs: knownMetricIDs)
        return copy
    }

    /// 선택 목록과 HUD 표시 시간을 규칙에 맞게 제자리에서 보정한다.
    public mutating func normalize(knownMetricIDs: [String]) {
        selectedMetricIDs = Self.normalizedSelection(selectedMetricIDs, knownMetricIDs: knownMetricIDs)
        hudDuration = Self.clampedHUDDuration(hudDuration)
    }

    /// 지표 선택 목록을 다음 순서로 보정한다.
    /// 1. registry에 없는 식별자를 버린다. 2. 중복을 버리고 첫 등장 순서를 유지한다.
    /// 3. 최대 3개로 자른다. 4. 비어 있으면 기본 지표(또는 registry 순서)로 최소 1개를 채운다.
    public static func normalizedSelection(_ ids: [String], knownMetricIDs: [String]) -> [String] {
        let known = Set(knownMetricIDs)
        var result: [String] = []
        var seen = Set<String>()
        for id in ids {
            guard known.contains(id), !seen.contains(id) else { continue }
            seen.insert(id)
            result.append(id)
        }
        if !result.isEmpty {
            return Array(result.prefix(maximumSelectedMetrics))
        }

        var fallback: [String] = []
        for id in defaultSelectedMetricIDs where known.contains(id) && !seen.contains(id) {
            seen.insert(id)
            fallback.append(id)
        }
        for id in knownMetricIDs where !seen.contains(id) {
            seen.insert(id)
            fallback.append(id)
        }
        return Array(fallback.prefix(maximumSelectedMetrics))
    }

    /// HUD 표시 시간을 0.1초 단위로 반올림한 뒤 0.5...2.0 범위로 클램프한다.
    /// NaN·무한대는 기본값 1.0으로 되돌린다.
    public static func clampedHUDDuration(_ value: Double) -> Double {
        guard value.isFinite else { return defaultHUDDuration }
        let rounded = (value * 10).rounded() / 10
        return min(max(rounded, hudDurationRange.lowerBound), hudDurationRange.upperBound)
    }
}
