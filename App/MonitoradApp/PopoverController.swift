import AppKit
import MonitoradUI
import SwiftUI

/// 팝오버 컨트롤러. SwiftUI 팝오버를 status item 버튼에 붙이고 transient로 동작시킨다.
final class PopoverController: NSObject, NSPopoverDelegate {
    private let popover = NSPopover()
    private let hostingController: NSHostingController<PopoverView>

    /// 팝오버를 열기 직전에 호출된다. 앱이 최신 상태로 모델을 채운다.
    var prepareForShow: (() -> Void)?

    /// transient 팝오버가 닫힌 직후 status item 클릭으로 곧바로 다시 열리는 것을 막는 간격.
    private static let reopenSuppressionInterval: TimeInterval = 0.3
    private var suppressToggleUntil = Date.distantPast

    init(model: PopoverModel) {
        hostingController = NSHostingController(rootView: PopoverView(model: model))
        super.init()
        hostingController.sizingOptions = [.preferredContentSize]
        popover.contentViewController = hostingController
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
    }

    var isShown: Bool {
        popover.isShown
    }

    /// 열려 있으면 닫고, 닫혀 있으면 연다. 방금 닫힌 직후의 재열기는 무시한다.
    func toggle(relativeTo button: NSStatusBarButton?) {
        if popover.isShown {
            close()
            return
        }
        guard Date() >= suppressToggleUntil, let button else { return }
        prepareForShow?()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    func close() {
        popover.performClose(nil)
        suppressToggleUntil = Date().addingTimeInterval(Self.reopenSuppressionInterval)
    }

    // MARK: - NSPopoverDelegate

    func popoverDidClose(_ notification: Notification) {
        suppressToggleUntil = Date().addingTimeInterval(Self.reopenSuppressionInterval)
    }
}
