import AppKit
import MonitoradCore
import MonitoradUI
import SwiftUI

/// 앱의 배선 지점. registry·설정·관측·status item·팝오버를 연결한다.
final class AppController {
    private let registry: MetricRegistry
    private let settingsStore: SettingsStore
    private let observationCoordinator: MetricObservationCoordinator
    private let indicatorModel: IndicatorModel
    private let popoverModel: PopoverModel
    private let statusItemController: StatusItemController
    private let popoverController: PopoverController
    private var refreshWorkItem: DispatchWorkItem?

    init() {
        let registry = MetricRegistry.makeDefault()
        let indicatorModel = IndicatorModel()
        let popoverModel = PopoverModel()

        self.registry = registry
        self.settingsStore = SettingsStore(knownMetricIDs: registry.ids)
        self.observationCoordinator = MetricObservationCoordinator(registry: registry)
        self.indicatorModel = indicatorModel
        self.popoverModel = popoverModel
        self.statusItemController = StatusItemController(indicatorModel: indicatorModel)
        self.popoverController = PopoverController(model: popoverModel)
    }

    // MARK: - 라이프사이클

    func start() {
        configurePopoverCallbacks()
        popoverController.prepareForShow = { [weak self] in
            self?.refreshPopoverState()
        }
        statusItemController.install { [weak self] in
            self?.togglePopover()
        }
        observationCoordinator.setChangeHandler { [weak self] _, _ in
            self?.scheduleIndicatorRefresh()
        }
        reconcileLaunchAtLogin()
        observationCoordinator.observe(metricIDs: settingsStore.settings.selectedMetricIDs)
        refreshIndicator()
    }

    func stop() {
        refreshWorkItem?.cancel()
        refreshWorkItem = nil
        observationCoordinator.stopAll()
        statusItemController.uninstall()
    }

    // MARK: - 팝오버 연결

    private func configurePopoverCallbacks() {
        popoverModel.onToggleMetric = { [weak self] metricID in
            self?.toggleMetric(metricID)
        }
        popoverModel.onMoveMetric = { [weak self] movingID, targetID in
            self?.moveMetric(movingID, before: targetID)
        }
        popoverModel.onHUDDurationChange = { [weak self] duration in
            self?.setHUDDuration(duration)
        }
        popoverModel.onLaunchAtLoginChange = { [weak self] enabled in
            self?.setLaunchAtLogin(enabled)
        }
        popoverModel.onReplacementEnabledChange = { [weak self] enabled in
            self?.setReplacementEnabled(enabled)
        }
        popoverModel.onOpenAccessibilitySettings = {
            NSWorkspace.shared.open(AccessibilityPermission.settingsURL)
        }
        popoverModel.onQuit = {
            NSApp.terminate(nil)
        }
    }

    private func togglePopover() {
        popoverController.toggle(relativeTo: statusItemController.button)
    }

    // MARK: - 인디케이터

    private func scheduleIndicatorRefresh() {
        guard refreshWorkItem == nil else { return }
        let work = DispatchWorkItem { [weak self] in
            self?.refreshWorkItem = nil
            self?.refreshIndicator()
        }
        refreshWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 / 30.0, execute: work)
    }

    private func refreshIndicator() {
        let displayMetrics = registry.resolveDisplayMetrics(selectedIDs: settingsStore.settings.selectedMetricIDs)
        let rings = displayMetrics.map { metric in
            RingModel(
                id: metric.id,
                name: metric.displayName,
                value: metric.value,
                tint: Color(metric.tint),
                symbolName: metric.symbolName
            )
        }
        statusItemController.update(rings: rings)
    }

    // MARK: - 설정 변경

    /// 설정을 보정·저장하고, 관측 집합과 인디케이터를 다시 맞춘다.
    private func updateSettings(_ mutate: (inout MonitoradSettings) -> Void) {
        var updated = settingsStore.settings
        mutate(&updated)
        settingsStore.update(updated)
        observationCoordinator.observe(metricIDs: settingsStore.settings.selectedMetricIDs)
        refreshIndicator()
    }

    private func toggleMetric(_ metricID: String) {
        let current = settingsStore.settings
        let isSelected = current.selectedMetricIDs.contains(metricID)

        if !isSelected, let metric = registry.metric(id: metricID), !metric.availability.isAvailable {
            popoverModel.statusMessage = metric.availability.unavailableReason
            return
        }

        let toggled = MetricSelectionPolicy.toggling(
            metricID,
            selectedIDs: current.selectedMetricIDs,
            knownMetricIDs: registry.ids
        )
        guard toggled != current.selectedMetricIDs else {
            popoverModel.statusMessage = MetricSelectionPolicy.selectionDisabledReason(
                metricID,
                selectedIDs: current.selectedMetricIDs,
                knownMetricIDs: registry.ids
            )
            return
        }

        popoverModel.statusMessage = nil
        updateSettings { $0.selectedMetricIDs = toggled }
        refreshPopoverRows()
    }

    private func moveMetric(_ movingID: String, before targetID: String) {
        let current = settingsStore.settings.selectedMetricIDs
        let moved = MetricSelectionPolicy.moving(movingID, before: targetID, selectedIDs: current)
        guard moved != current else { return }
        updateSettings { $0.selectedMetricIDs = moved }
        refreshPopoverRows()
    }

    private func setHUDDuration(_ duration: Double) {
        updateSettings { $0.hudDuration = duration }
        // 0.1초 단위 클램프 결과를 슬라이더 표시에 되돌린다.
        popoverModel.hudDuration = settingsStore.settings.hudDuration
    }

    private func setReplacementEnabled(_ enabled: Bool) {
        updateSettings { $0.replacementEnabled = enabled }
        popoverModel.replacementEnabled = settingsStore.settings.replacementEnabled
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try LaunchAtLogin.setEnabled(enabled)
            let actual = LaunchAtLogin.isEnabled
            updateSettings { $0.launchAtLogin = actual }
            popoverModel.launchAtLogin = actual
            popoverModel.statusMessage = nil
        } catch {
            popoverModel.launchAtLogin = LaunchAtLogin.isEnabled
            popoverModel.statusMessage = "로그인 시 시작을 바꾸지 못했습니다: \(error.localizedDescription)"
        }
    }

    /// 저장된 값과 실제 SMAppService 상태가 다르면 실제 상태로 맞춘다.
    private func reconcileLaunchAtLogin() {
        let actual = LaunchAtLogin.isEnabled
        guard settingsStore.settings.launchAtLogin != actual else { return }
        settingsStore.mutate { $0.launchAtLogin = actual }
    }

    // MARK: - 팝오버 상태

    private func refreshPopoverState() {
        popoverModel.hudDuration = settingsStore.settings.hudDuration
        popoverModel.replacementEnabled = settingsStore.settings.replacementEnabled
        popoverModel.showsAccessibilityNotice = !AccessibilityPermission.isTrusted
        popoverModel.statusMessage = nil

        let actual = LaunchAtLogin.isEnabled
        popoverModel.launchAtLogin = actual
        if settingsStore.settings.launchAtLogin != actual {
            updateSettings { $0.launchAtLogin = actual }
        }
        refreshPopoverRows()
    }

    private func refreshPopoverRows() {
        let settings = settingsStore.settings
        let selected = settings.selectedMetricIDs
        let ordered = registry.resolveAll(selectedIDs: selected)
            + registry.metrics.filter { !selected.contains($0.id) }

        popoverModel.rows = ordered.map { metric in
            let isSelected = selected.contains(metric.id)
            let unavailableReason = metric.availability.unavailableReason
            let disabledReason: String?
            if isSelected {
                disabledReason = MetricSelectionPolicy.selectionDisabledReason(
                    metric.id,
                    selectedIDs: selected,
                    knownMetricIDs: registry.ids
                )
            } else if let unavailableReason {
                disabledReason = unavailableReason
            } else {
                disabledReason = MetricSelectionPolicy.selectionDisabledReason(
                    metric.id,
                    selectedIDs: selected,
                    knownMetricIDs: registry.ids
                )
            }

            return MetricRowModel(
                id: metric.id,
                displayName: metric.displayName,
                tint: Color(metric.tint),
                isSelected: isSelected,
                unavailableReason: unavailableReason,
                selectionDisabledReason: disabledReason
            )
        }
    }
}
