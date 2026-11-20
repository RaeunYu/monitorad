#!/usr/bin/env swift
//
// generate-app-icon.swift
// monitorad 앱 아이콘 생성 스크립트.
//
// 디자인(1024×1024 기준, Lead 사양):
// - 콘텐츠는 코너 반경 232의 둥근 사각형, 배경은 위→아래 #1B1C1E → #2C2E32 세로 그라데이션.
// - 중앙(512, 500, 위에서 잰 좌표)에 추상 게이지 모티프 3중 링:
//   - 바깥: r=300, 두께 54, #30D158, -90°(아래)에서 시계방향 270°, 둥근 캡
//   - 중간: r=205, 두께 40, 같은 초록 62% 불투명, -90°에서 170°, 둥근 캡
//   - 중앙: 흰색 원 r=40 (#F2FFF4), 살짝 그림자
// - sun/speaker 같은 시스템 글리프를 모방하지 않는 추상 형태.
//
// 실행: 리포 루트에서 `swift Scripts/generate-app-icon.swift`
// 출력: App/Resources/Assets.xcassets/AppIcon.appiconset/icon_{16,32,64,128,256,512,1024}.png
//       App/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json
//       App/Resources/Assets.xcassets/Contents.json
//
// macOS 11+ (UniformTypeIdentifiers). CoreGraphics로 그려 크기별로 다시 렌더링한다.

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

// MARK: - 디자인 상수 (1024 기준 좌표)

private enum Design {
    static let canvas: CGFloat = 1024
    static let cornerRadius: CGFloat = 232

    static let backgroundColorTop = CGColor(red: 27 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1)
    static let backgroundColorBottom = CGColor(red: 44 / 255, green: 46 / 255, blue: 50 / 255, alpha: 1)
    static let accentColor = CGColor(red: 48 / 255, green: 209 / 255, blue: 88 / 255, alpha: 1)
    static let centerColor = CGColor(red: 242 / 255, green: 255 / 255, blue: 244 / 255, alpha: 1)

    /// 위에서 잰 중앙 좌표 (CoreGraphics는 y가 위로 증가하므로 뒤집는다).
    static let center = CGPoint(x: 512, y: canvas - 500)

    static let outerRadius: CGFloat = 300
    static let outerLineWidth: CGFloat = 54
    static let outerSweepDegrees: CGFloat = 270

    static let middleRadius: CGFloat = 205
    static let middleLineWidth: CGFloat = 40
    static let middleOpacity: CGFloat = 0.62
    static let middleSweepDegrees: CGFloat = 170

    static let centerRadius: CGFloat = 40
}

private let pngSizes = [16, 32, 64, 128, 256, 512, 1024]

private func degreesToRadians(_ degrees: CGFloat) -> CGFloat {
    degrees * .pi / 180
}

// MARK: - 렌더링

private func drawBackground(in context: CGContext) {
    let roundedRect = CGPath(
        roundedRect: CGRect(x: 0, y: 0, width: Design.canvas, height: Design.canvas),
        cornerWidth: Design.cornerRadius,
        cornerHeight: Design.cornerRadius,
        transform: nil
    )
    context.saveGState()
    context.addPath(roundedRect)
    context.clip()

    guard let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [Design.backgroundColorTop, Design.backgroundColorBottom] as CFArray,
        locations: [0, 1]
    ) else {
        context.restoreGState()
        return
    }
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: Design.canvas),
        end: CGPoint(x: 0, y: 0),
        options: []
    )
    context.restoreGState()
}

private func strokeArc(
    in context: CGContext,
    radius: CGFloat,
    lineWidth: CGFloat,
    color: CGColor,
    sweepDegrees: CGFloat
) {
    context.saveGState()
    context.setStrokeColor(color)
    context.setLineWidth(lineWidth)
    context.setLineCap(.round)
    let startAngle = -CGFloat.pi / 2 // 위에서 잰 -90°(아래)
    let endAngle = startAngle - degreesToRadians(sweepDegrees)
    let path = CGMutablePath()
    path.addArc(
        center: Design.center,
        radius: radius,
        startAngle: startAngle,
        endAngle: endAngle,
        clockwise: true
    )
    context.addPath(path)
    context.strokePath()
    context.restoreGState()
}

private func drawGaugeMotif(in context: CGContext) {
    // 바깥 링: -90°에서 시계방향 270° (오른쪽 아래 90° 갭).
    strokeArc(
        in: context,
        radius: Design.outerRadius,
        lineWidth: Design.outerLineWidth,
        color: Design.accentColor,
        sweepDegrees: Design.outerSweepDegrees
    )

    // 중간 링: 같은 초록 62% 불투명, -90°에서 170°.
    let middleColor = Design.accentColor.copy(alpha: Design.middleOpacity) ?? Design.accentColor
    strokeArc(
        in: context,
        radius: Design.middleRadius,
        lineWidth: Design.middleLineWidth,
        color: middleColor,
        sweepDegrees: Design.middleSweepDegrees
    )

    // 중앙 흰 원 + 살짝 그림자.
    context.saveGState()
    context.setShadow(
        offset: CGSize(width: 0, height: -6),
        blur: 18,
        color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.35)
    )
    context.setFillColor(Design.centerColor)
    context.fillEllipse(in: CGRect(
        x: Design.center.x - Design.centerRadius,
        y: Design.center.y - Design.centerRadius,
        width: Design.centerRadius * 2,
        height: Design.centerRadius * 2
    ))
    context.restoreGState()
}

private func renderIcon(pixelSize: Int) -> CGImage? {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: pixelSize,
        height: pixelSize,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        return nil
    }
    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)
    context.interpolationQuality = .high
    context.clear(CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize))

    let scale = CGFloat(pixelSize) / Design.canvas
    context.scaleBy(x: scale, y: scale)

    drawBackground(in: context)
    drawGaugeMotif(in: context)
    return context.makeImage()
}

// MARK: - 파일 쓰기

private func writePNG(_ image: CGImage, to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
    ) else {
        throw NSError(domain: "generate-app-icon", code: 1, userInfo: [NSLocalizedDescriptionKey: "PNG destination 생성 실패: \(url.path)"])
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw NSError(domain: "generate-app-icon", code: 2, userInfo: [NSLocalizedDescriptionKey: "PNG 저장 실패: \(url.path)"])
    }
}

private func write(appIconsContentsJSONTo url: URL) throws {
    let images = [
        (filename: "icon_16.png", size: "16x16", scale: "1x", pixelSize: 16),
        (filename: "icon_32.png", size: "16x16", scale: "2x", pixelSize: 32),
        (filename: "icon_32.png", size: "32x32", scale: "1x", pixelSize: 32),
        (filename: "icon_64.png", size: "32x32", scale: "2x", pixelSize: 64),
        (filename: "icon_128.png", size: "128x128", scale: "1x", pixelSize: 128),
        (filename: "icon_256.png", size: "128x128", scale: "2x", pixelSize: 256),
        (filename: "icon_256.png", size: "256x256", scale: "1x", pixelSize: 256),
        (filename: "icon_512.png", size: "256x256", scale: "2x", pixelSize: 512),
        (filename: "icon_512.png", size: "512x512", scale: "1x", pixelSize: 512),
        (filename: "icon_1024.png", size: "512x512", scale: "2x", pixelSize: 1024),
    ]
    var lines: [String] = []
    lines.append("{")
    lines.append("  \"images\" : [")
    for (index, image) in images.enumerated() {
        let comma = index == images.count - 1 ? "" : ","
        lines.append("    {")
        lines.append("      \"filename\" : \"\(image.filename)\",")
        lines.append("      \"idiom\" : \"mac\",")
        lines.append("      \"scale\" : \"\(image.scale)\",")
        lines.append("      \"size\" : \"\(image.size)\"")
        lines.append("    }\(comma)")
    }
    lines.append("  ],")
    lines.append("  \"info\" : {")
    lines.append("    \"author\" : \"xcode\",")
    lines.append("    \"version\" : 1")
    lines.append("  }")
    lines.append("}")
    try lines.joined(separator: "\n").appending("\n").write(to: url, atomically: true, encoding: .utf8)
}

private func write(assetCatalogContentsJSONTo url: URL) throws {
    let contents = """
    {
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }

    """
    try contents.write(to: url, atomically: true, encoding: .utf8)
}

// MARK: - 실행

private let scriptURL = URL(fileURLWithPath: #filePath)
private let repoRoot = scriptURL
    .deletingLastPathComponent() // Scripts/
    .deletingLastPathComponent() // repo root
private let defaultOutput = repoRoot
    .appendingPathComponent("App/Resources/Assets.xcassets/AppIcon.appiconset", isDirectory: true)
private let outputDirectory = CommandLine.arguments.count > 1
    ? URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
    : defaultOutput
private let assetCatalogDirectory = outputDirectory.deletingLastPathComponent()

do {
    try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

    for pixelSize in pngSizes {
        guard let image = renderIcon(pixelSize: pixelSize) else {
            throw NSError(domain: "generate-app-icon", code: 3, userInfo: [NSLocalizedDescriptionKey: "\(pixelSize)px 렌더링 실패"])
        }
        let fileURL = outputDirectory.appendingPathComponent("icon_\(pixelSize).png")
        try writePNG(image, to: fileURL)
        print("generated \(fileURL.path) (\(pixelSize)×\(pixelSize))")
    }

    try write(appIconsContentsJSONTo: outputDirectory.appendingPathComponent("Contents.json"))
    try write(assetCatalogContentsJSONTo: assetCatalogDirectory.appendingPathComponent("Contents.json"))
    print("wrote Contents.json for \(assetCatalogDirectory.path)")
} catch {
    FileHandle.standardError.write(Data("error: \(error.localizedDescription)\n".utf8))
    exit(1)
}
