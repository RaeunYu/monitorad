import MonitoradCore
import SwiftUI

/// 메뉴바 인디케이터에 그리는 링 하나.
public struct RingModel: Identifiable {
    public let id: String
    public let name: String
    public let value: Double
    public let tint: Color
    public let symbolName: String

    public init(id: String, name: String, value: Double, tint: Color, symbolName: String) {
        self.id = id
        self.name = name
        self.value = value
        self.tint = tint
        self.symbolName = symbolName
    }
}

/// 지표 하나를 표현하는 진행률 링. 진행률 arc와 지표별 색·아이콘을 그린다.
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
