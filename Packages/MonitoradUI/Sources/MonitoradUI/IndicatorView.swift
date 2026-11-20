import MonitoradCore
import SwiftUI

/// 메뉴바 인디케이터가 관찰하는 값 묶음. 앱이 링 목록을 갱신하면 뷰가 다시 그린다.
public final class IndicatorModel: ObservableObject {
    @Published public private(set) var rings: [RingModel]
    /// 표시할 지표가 없을 때 placeholder와 함께 노출할 사유. 링이 있으면 nil.
    @Published public private(set) var placeholderReason: String?

    public init(rings: [RingModel] = [], placeholderReason: String? = nil) {
        self.rings = rings
        self.placeholderReason = placeholderReason
    }

    public func update(rings: [RingModel], placeholderReason: String? = nil) {
        self.rings = rings
        self.placeholderReason = rings.isEmpty ? placeholderReason : nil
    }
}

/// `NSStatusItem` 항목 안에 들어가는 링 인디케이터.
/// 지표 1개면 큰 링, 2~3개면 작은 링을 나란히 그린다 (ADR-0003). 표시할 지표가 없으면 placeholder를 그린다.
public struct IndicatorView: View {
    @ObservedObject private var model: IndicatorModel

    public init(model: IndicatorModel) {
        self.model = model
    }

    public var body: some View {
        Group {
            if let layout = IndicatorLayout.resolve(metricCount: model.rings.count) {
                HStack(spacing: layout.ringSpacing) {
                    ForEach(model.rings) { ring in
                        RingView(
                            progress: ring.value,
                            tint: ring.tint,
                            symbolName: ring.symbolName,
                            diameter: layout.ringDiameter,
                            lineWidth: max(2.0, layout.ringDiameter * 0.13)
                        )
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(accessibilityLabel(for: ring)))
                    }
                }
                .frame(width: layout.itemWidth, height: layout.height)
            } else {
                Image(systemName: "circle.dashed")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 22)
                    .help(placeholderMessage)
                    .accessibilityLabel(Text(placeholderMessage))
            }
        }
    }

    private var placeholderMessage: String {
        model.placeholderReason ?? IndicatorEmptyState.defaultMessage
    }

    private func accessibilityLabel(for ring: RingModel) -> String {
        "\(ring.name) \(Int((min(max(ring.value, 0), 1) * 100).rounded()))퍼센트"
    }
}
