import CoreGraphics

/// 메뉴바 status item이 화면 밖으로 밀렸는지 판정한다 (ADR-0003 방어 로직).
///
/// Tahoe에서 항목이 `(0, -17, 34×22)`처럼 화면 밖으로 밀리는 사례가 보고됐다.
/// 앱은 항목을 추가한 직후 이 판정을 하고, 참이면 remove + re-add를 시도한다.
public enum MenuBarPlacementGuard {
    /// 재추가를 시도하는 최대 횟수. 무한 루프를 막는다.
    public static let maximumReinstallAttempts = 3

    /// 재추가가 필요한지 판정한다.
    /// - Parameters:
    ///   - itemFrame: status item 버튼 창의 화면 좌표 프레임.
    ///   - screenFrames: 현재 연결된 화면들의 프레임.
    ///   - isWindowVisible: 버튼 창이 보이는 상태인지.
    /// - Returns: 창이 비가시이거나, 프레임이 화면과 거의 겹치지 않으면 true.
    public static func shouldReinstall(
        itemFrame: CGRect,
        screenFrames: [CGRect],
        isWindowVisible: Bool
    ) -> Bool {
        guard isWindowVisible else { return true }
        guard !screenFrames.isEmpty else { return false }
        guard itemFrame.width > 0, itemFrame.height > 0, itemFrame.isNull == false else { return true }

        let originOnScreen = screenFrames.contains { $0.contains(itemFrame.origin) }
        guard originOnScreen else { return true }

        let visibleArea = screenFrames.reduce(0.0) { partial, screen in
            let intersection = screen.intersection(itemFrame)
            guard intersection.isNull == false else { return partial }
            return partial + intersection.width * intersection.height
        }
        return visibleArea < itemFrame.width * itemFrame.height * 0.5
    }
}
