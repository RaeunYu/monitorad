import Foundation
import SwiftUI

/// 팝오버의 지표 체크리스트 한 줄.
public struct MetricRowModel: Identifiable {
    /// 지표 식별자.
    public let id: String
    /// 표시명.
    public let displayName: String
    /// 체크 표시에 쓰는 지표별 색.
    public let tint: Color
    /// 현재 표시 대상으로 선택되었는지.
    public let isSelected: Bool
    /// 이 환경에서 값을 읽을 수 없는 사유. 사용 가능하면 nil.
    public let unavailableReason: String?
    /// 체크를 바꿀 수 없는 사유(최대 3개·최소 1개·미지원). 가능하면 nil.
    public let selectionDisabledReason: String?

    public init(
        id: String,
        displayName: String,
        tint: Color,
        isSelected: Bool,
        unavailableReason: String?,
        selectionDisabledReason: String?
    ) {
        self.id = id
        self.displayName = displayName
        self.tint = tint
        self.isSelected = isSelected
        self.unavailableReason = unavailableReason
        self.selectionDisabledReason = selectionDisabledReason
    }
}

/// 팝오버가 표시하는 상태와, 사용자 조작을 앱으로 넘기는 콜백 묶음.
/// 앱이 `refresh`로 상태를 채우고, 뷰는 콜백만 호출한다.
public final class PopoverModel: ObservableObject {
    @Published public var rows: [MetricRowModel] = []
    @Published public var hudDuration: Double = 1.0
    @Published public var launchAtLogin: Bool = false
    @Published public var replacementEnabled: Bool = false
    @Published public var showsAccessibilityNotice: Bool = false
    @Published public var statusMessage: String?

    public var onToggleMetric: ((_ metricID: String) -> Void)?
    /// (옮길 지표 ID, 이 지표 앞으로) 순서 변경.
    public var onMoveMetric: ((_ movingID: String, _ targetID: String) -> Void)?
    public var onHUDDurationChange: ((_ duration: Double) -> Void)?
    public var onLaunchAtLoginChange: ((_ enabled: Bool) -> Void)?
    public var onReplacementEnabledChange: ((_ enabled: Bool) -> Void)?
    public var onOpenAccessibilitySettings: (() -> Void)?
    public var onQuit: (() -> Void)?

    public init() {}
}
