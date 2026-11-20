import MonitoradCore
import SwiftUI

/// 지표 하나를 표현하는 진행률 링. 진행률 arc와 지표별 색·아이콘을 그린다.
/// 링 표시 모델(`RingModel`)과 레이아웃은 Core의 ``IndicatorPresentation``이 계산하고,
/// 이 뷰는 그 결과를 그리기만 한다.
public struct RingView: View {
    public let progress: Double
    public let tint: Color
    public let symbolName: String
    public let diameter: Double
    public let lineWidth: Double

    public init(progress: Double, tint: Color, symbolName: String, diameter: Double, lineWidth: Double) {
        self.progress = progress
        self.tint = tint
        self.symbolName = symbolName
        self.diameter = diameter
        self.lineWidth = lineWidth
    }

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    public var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.primary.opacity(0.22), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    tint,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Image(systemName: symbolName)
                .font(.system(size: diameter * 0.40, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: diameter, height: diameter)
        .animation(.easeOut(duration: 0.12), value: clampedProgress)
    }
}
