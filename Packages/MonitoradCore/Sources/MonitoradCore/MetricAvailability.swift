import Foundation

/// 지표를 지금 표시할 수 있는지와, 표시할 수 없을 때의 사용자 사유.
public enum MetricAvailability: Equatable {
    /// 값을 읽을 수 있어 표시할 수 있다.
    case available

    /// 이 환경에서 값을 읽을 수 없다. 앱은 계속 동작하고, 해당 지표만 비활성으로 둔다.
    case unavailable(reason: String)

    public var isAvailable: Bool {
        if case .available = self {
            return true
        }
        return false
    }

    /// 사용할 수 없을 때 팝오버에 보여 줄 사유. 사용 가능하면 nil.
    public var unavailableReason: String? {
        if case let .unavailable(reason) = self {
            return reason
        }
        return nil
    }
}
