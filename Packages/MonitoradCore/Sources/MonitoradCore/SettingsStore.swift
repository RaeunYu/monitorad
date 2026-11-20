import Foundation

/// 설정을 UserDefaults에 Codable로 읽고 쓴다.
/// 읽어 온 값과 저장하는 값 모두 규칙 보정을 거친다.
public final class SettingsStore {
    /// UserDefaults 키. 값은 JSON으로 인코딩한 ``MonitoradSettings``다.
    public static let defaultsKey = "com.monitorad.settings"

    private let defaults: UserDefaults
    private let knownMetricIDs: [String]

    /// 마지막으로 읽거나 저장한, 규칙이 적용된 설정.
    public private(set) var settings: MonitoradSettings

    public init(defaults: UserDefaults = .standard, knownMetricIDs: [String] = MetricID.builtIn) {
        self.defaults = defaults
        self.knownMetricIDs = knownMetricIDs
        let loaded = Self.loadSettings(from: defaults) ?? .default
        self.settings = loaded.normalized(knownMetricIDs: knownMetricIDs)
    }

    /// 설정을 보정한 뒤 저장한다. 항상 규칙이 적용된 값이 남는다.
    public func update(_ newSettings: MonitoradSettings) {
        let normalized = newSettings.normalized(knownMetricIDs: knownMetricIDs)
        settings = normalized
        persist(normalized)
    }

    /// 현재 설정을 제자리에서 고친 뒤 저장한다.
    public func mutate(_ body: (inout MonitoradSettings) -> Void) {
        var copy = settings
        body(&copy)
        update(copy)
    }

    /// 저장소에서 다시 읽는다.
    public func reload() {
        let loaded = Self.loadSettings(from: defaults) ?? .default
        settings = loaded.normalized(knownMetricIDs: knownMetricIDs)
    }

    private func persist(_ settings: MonitoradSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: Self.defaultsKey)
    }

    private static func loadSettings(from defaults: UserDefaults) -> MonitoradSettings? {
        guard let data = defaults.data(forKey: defaultsKey) else { return nil }
        return try? JSONDecoder().decode(MonitoradSettings.self, from: data)
    }
}
