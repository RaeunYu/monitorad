import AppKit
import MonitoradCore
import MonitoradUI
import SwiftUI

/// 호스팅 뷰가 status item 버튼의 클릭을 가로채지 않도록 hitTest를 비활성화한다.
final class PassThroughHostingView<Content: View>: NSHostingView<Content> {
    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }
}

/// `NSStatusItem` 하나를 만들고 SwiftUI 링 인디케이터를 얹는다.
/// 추가 직후 프레임을 검사해 화면 밖으로 밀렸으면 remove + re-add로 복구를 시도한다 (ADR-0003).
final class StatusItemController: NSObject {
    private let indicatorModel: IndicatorModel
    private var statusItem: NSStatusItem?
    private var toggleHandler: (() -> Void)?
    private var reinstallAttempts = 0

    /// status item의 autosave 이름. 위치·가시성 복원에 쓰인다.
    static let autosaveName = "com.monitorad.indicator"

    init(indicatorModel: IndicatorModel) {
        self.indicatorModel = indicatorModel
        super.init()
    }

    /// 팝오버를 여는 기준이 되는 버튼.
    var button: NSStatusBarButton? {
        statusItem?.button
    }

    /// status item을 설치한다. 다시 호출하면 기존 항목을 지우고 새로 만든다.
    func install(onToggle: @escaping () -> Void) {
        toggleHandler = onToggle
        reinstallAttempts = 0
        buildStatusItem()
    }

    func uninstall() {
        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        statusItem = nil
    }

    /// Core가 계산한 인디케이터 표시 상태를 갱신하고 항목 폭을 링 수에 맞춘다.
    func update(presentation: IndicatorPresentation) {
        indicatorModel.update(presentation: presentation)
        applyLayout()
    }

    @objc private func handleClick() {
        toggleHandler?()
    }

    // MARK: - 생성

    private func buildStatusItem() {
        if let existing = statusItem {
            NSStatusBar.system.removeStatusItem(existing)
        }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.autosaveName = Self.autosaveName
        item.isVisible = true

        let hosting = PassThroughHostingView(rootView: IndicatorView(model: indicatorModel))
        hosting.translatesAutoresizingMaskIntoConstraints = false

        if let button = item.button {
            button.addSubview(hosting)
            NSLayoutConstraint.activate([
                hosting.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                hosting.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                hosting.topAnchor.constraint(equalTo: button.topAnchor),
                hosting.bottomAnchor.constraint(equalTo: button.bottomAnchor),
            ])
            button.target = self
            button.action = #selector(handleClick)
            _ = button.sendAction(on: [.leftMouseUp])
            button.toolTip = String(localized: "statusItem.toolTip")
        }

        statusItem = item
        applyLayout()
        schedulePlacementVerification()
    }

    private func applyLayout() {
        guard let item = statusItem else { return }
        item.length = indicatorModel.presentation.layout.map { CGFloat($0.itemWidth) } ?? 24
    }

    // MARK: - 방어 재추가

    private func schedulePlacementVerification() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.verifyPlacement()
        }
    }

    private func verifyPlacement() {
        guard let item = statusItem, let window = item.button?.window else {
            reinstallIfNeeded()
            return
        }
        let shouldReinstall = MenuBarPlacementGuard.shouldReinstall(
            itemFrame: window.frame,
            screenFrames: NSScreen.screens.map(\.frame),
            isWindowVisible: window.isVisible
        )
        if shouldReinstall {
            reinstallIfNeeded()
        }
    }

    private func reinstallIfNeeded() {
        guard reinstallAttempts < MenuBarPlacementGuard.maximumReinstallAttempts else { return }
        reinstallAttempts += 1
        buildStatusItem()
    }
}
