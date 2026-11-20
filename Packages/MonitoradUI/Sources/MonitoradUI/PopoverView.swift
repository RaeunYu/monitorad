import Foundation
import MonitoradCore
import SwiftUI

/// 메뉴바 인디케이터를 클릭하면 펼쳐지는 설정 패널.
/// 지표 선택·순서, HUD 표시 시간, 로그인 시 시작, HUD 대체 토글, 종료, Accessibility 안내를 담는다.
public struct PopoverView: View {
    @ObservedObject private var model: PopoverModel

    public init(model: PopoverModel) {
        self.model = model
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            metricList
            Divider()
            durationSection
            Divider()
            behaviorSection
            if model.showsAccessibilityNotice {
                accessibilitySection
            }
            if let message = model.statusMessage {
                Text(message)
                    .font(.system(size: 10))
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Divider()
            footer
        }
        .padding(16)
        .frame(width: 320)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(String(localized: "popover.title"))
                .font(.system(size: 13, weight: .semibold))
            Text(String(localized: "popover.description"))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    private var metricList: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(model.rows) { row in
                MetricRowView(
                    row: row,
                    onToggle: { model.onToggleMetric?(row.id) },
                    onMove: { movingID in model.onMoveMetric?(movingID, row.id) }
                )
            }
        }
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(localized: "popover.duration.title"))
                .font(.system(size: 12))
            HStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: { model.hudDuration },
                        set: { newValue in
                            model.hudDuration = newValue
                            model.onHUDDurationChange?(newValue)
                        }
                    ),
                    in: MonitoradSettings.hudDurationRange,
                    step: 0.1
                )
                Text(String(format: String(localized: "popover.duration.value"), model.hudDuration))
                    .font(.system(size: 11).monospacedDigit())
                    .frame(width: 38, alignment: .trailing)
            }
            Text(String(localized: "popover.duration.footnote"))
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
    }

    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(
                isOn: Binding(
                    get: { model.launchAtLogin },
                    set: { newValue in
                        model.launchAtLogin = newValue
                        model.onLaunchAtLoginChange?(newValue)
                    }
                )
            ) {
                Text(String(localized: "popover.launchAtLogin"))
                    .font(.system(size: 12))
            }
            .toggleStyle(.switch)
            .controlSize(.small)

            Toggle(
                isOn: Binding(
                    get: { model.replacementEnabled },
                    set: { newValue in
                        model.replacementEnabled = newValue
                        model.onReplacementEnabledChange?(newValue)
                    }
                )
            ) {
                Text(String(localized: "popover.hudReplacement"))
                    .font(.system(size: 12))
            }
            .toggleStyle(.switch)
            .controlSize(.small)

            Text(String(localized: "popover.hudReplacement.footnote"))
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var accessibilitySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.yellow)
                Text(AccessibilityNotice.message)
                    .font(.system(size: 11))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button(String(localized: "popover.accessibility.openSettings")) {
                model.onOpenAccessibilitySettings?()
            }
            .controlSize(.small)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.secondary.opacity(0.10))
        )
    }

    private var footer: some View {
        HStack {
            Text(String(format: String(localized: "popover.version"), AppVersion.display))
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
            Spacer()
            Button(String(localized: "popover.quit")) {
                model.onQuit?()
            }
            .controlSize(.small)
        }
    }
}

/// 팝오버의 지표 체크리스트 한 줄. 왼쪽 체크 버튼과 오른쪽 드래그 손잡이로 조작한다.
private struct MetricRowView: View {
    let row: MetricRowModel
    let onToggle: () -> Void
    let onMove: (String) -> Void

    @State private var isDropTarget = false

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onToggle) {
                Image(systemName: row.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(row.isSelected ? row.tint : Color.secondary)
            }
            .buttonStyle(.plain)
            .disabled(row.selectionDisabledReason != nil)

            VStack(alignment: .leading, spacing: 1) {
                Text(row.displayName)
                    .font(.system(size: 12))
                if let reason = row.unavailableReason {
                    Text(reason)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else if let reason = row.selectionDisabledReason {
                    Text(reason)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if row.isSelected {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .draggable(row.id)
                    .help(String(localized: "popover.reorder.help"))
            }
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(isDropTarget ? Color.secondary.opacity(0.12) : Color.clear)
        )
        .contentShape(Rectangle())
        .dropDestination(for: String.self) { items, _ in
            guard let movingID = items.first, movingID != row.id else { return false }
            onMove(movingID)
            return true
        } isTargeted: { targeted in
            isDropTarget = targeted
        }
    }
}

/// 앱 번들에서 읽은 버전 문자열. 번들 정보가 없으면 v0.1로 표시한다.
public enum AppVersion {
    public static var display: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "0.1"
    }
}
