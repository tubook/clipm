#!/usr/bin/env swift
import Cocoa
import CoreText

/// Renders native Apple HIG Retina DMG backgrounds using real SF Pro, SF Mono,
/// and SF Symbols directly on macOS so typography and icons are razor-sharp.
func renderBackground(scale: CGFloat, outputPath: String) {
    // Visual layout matches the 660x420 Finder content area, while the canvas
    // bleeds to 800x520 so Finder never reveals a white strip on the right/bottom.
    let layoutWidth: CGFloat = 660
    let width: CGFloat = 800
    let height: CGFloat = 520
    let pixelW = Int(width * scale)
    let pixelH = Int(height * scale)

    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelW,
        pixelsHigh: pixelH,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("Failed to create bitmap representation")
    }
    rep.size = NSSize(width: width, height: height)

    NSGraphicsContext.saveGraphicsState()
    guard let ctx = NSGraphicsContext(bitmapImageRep: rep) else {
        fatalError("Failed to create NSGraphicsContext")
    }
    NSGraphicsContext.current = ctx
    ctx.shouldAntialias = true
    ctx.imageInterpolation = .high

    // Keep native unflipped AppKit/CoreGraphics coordinates (origin at bottom-left)
    // so text, SF Symbols, gradients, and shadows all render upright consistently.
    let cg = ctx.cgContext
    let ctColorKey = NSAttributedString.Key(kCTForegroundColorAttributeName as String)

    // Convert a top-down Y coordinate into native bottom-up coordinates.
    func yFromTop(_ topY: CGFloat) -> CGFloat {
        height - topY
    }

    // 1. Clean, seamless Apple porcelain-silver vertical gradient (no outer box border)
    let topColor = NSColor(srgbRed: 0.965, green: 0.970, blue: 0.980, alpha: 1.0)
    let botColor = NSColor(srgbRed: 0.918, green: 0.928, blue: 0.946, alpha: 1.0)
    if let grad = NSGradient(starting: topColor, ending: botColor) {
        grad.draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: -90)
    }

    // Subtle soft radial highlight behind the center area
    let glowCenter = NSPoint(x: layoutWidth / 2, y: yFromTop(195))
    let glowColors = [
        NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.55),
        NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.0),
    ]
    if let radial = NSGradient(colors: glowColors) {
        radial.draw(fromCenter: glowCenter, radius: 0, toCenter: glowCenter, radius: 260, options: [])
    }

    // Helper: draw attributed text horizontally & vertically centered at (layoutWidth / 2, centerYFromTop)
    func drawCenteredText(_ attr: NSAttributedString, centerYFromTop: CGFloat) {
        let line = CTLineCreateWithAttributedString(attr)
        let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        cg.saveGState()
        cg.textMatrix = .identity
        cg.textPosition = CGPoint(
            x: layoutWidth / 2.0 - bounds.midX,
            y: yFromTop(centerYFromTop) - bounds.midY
        )
        CTLineDraw(line, cg)
        cg.restoreGState()
    }

    // 2. Title ("clipm") in native Apple SF Pro Display Bold
    let titleFont = NSFont.systemFont(ofSize: 28, weight: .bold)
    let titleColor = NSColor(srgbRed: 0.08, green: 0.09, blue: 0.12, alpha: 1.0)
    let titleAttr = NSAttributedString(
        string: "clipm",
        attributes: [
            .font: titleFont,
            ctColorKey: titleColor.cgColor,
            .kern: -0.6,
        ]
    )
    drawCenteredText(titleAttr, centerYFromTop: 50)

    // 3. Subtitle in native Apple SF Pro Text Regular
    let subFont = NSFont.systemFont(ofSize: 13.5, weight: .regular)
    let subColor = NSColor(srgbRed: 0.42, green: 0.46, blue: 0.52, alpha: 1.0)
    let subAttr = NSAttributedString(
        string: "Drag to Applications to install",
        attributes: [
            .font: subFont,
            ctColorKey: subColor.cgColor,
            .kern: -0.1,
        ]
    )
    drawCenteredText(subAttr, centerYFromTop: 78)

    // 4. Perfect circular badge + native Apple SF Symbol "arrow.right" centered at (330, 200)
    let circleDiameter: CGFloat = 46
    let circleCenterY = yFromTop(200)
    let circleRect = NSRect(
        x: (layoutWidth - circleDiameter) / 2.0,
        y: circleCenterY - circleDiameter / 2.0,
        width: circleDiameter,
        height: circleDiameter
    )

    cg.saveGState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor(srgbRed: 0.06, green: 0.09, blue: 0.16, alpha: 0.10)
    shadow.shadowOffset = NSSize(width: 0, height: -2)
    shadow.shadowBlurRadius = 10
    shadow.set()

    let circlePath = NSBezierPath(ovalIn: circleRect)
    NSColor.white.setFill()
    circlePath.fill()
    cg.restoreGState()

    NSColor(srgbRed: 0.82, green: 0.85, blue: 0.90, alpha: 1.0).setStroke()
    circlePath.lineWidth = 1.0
    circlePath.stroke()

    if let sym = NSImage(systemSymbolName: "arrow.right", accessibilityDescription: nil) {
        let cfg = NSImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
            .applying(NSImage.SymbolConfiguration(paletteColors: [
                NSColor(srgbRed: 0.04, green: 0.52, blue: 1.0, alpha: 1.0),
            ]))
        if let styled = sym.withSymbolConfiguration(cfg) {
            let sSize = styled.size
            let drawRect = NSRect(
                x: (layoutWidth - sSize.width) / 2.0,
                y: circleCenterY - sSize.height / 2.0,
                width: sSize.width,
                height: sSize.height
            )
            styled.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1.0, respectFlipped: true, hints: nil)
        }
    }

    // 5. Bottom shortcut pill — exact glyph-bounds horizontal & vertical centering
    let keyFont = NSFont.monospacedSystemFont(ofSize: 11.5, weight: .semibold)
    let hintFont = NSFont.systemFont(ofSize: 11.5, weight: .medium)
    let keyColor = NSColor(srgbRed: 0.95, green: 0.97, blue: 1.0, alpha: 1.0)
    let hintColor = NSColor(srgbRed: 0.64, green: 0.69, blue: 0.77, alpha: 1.0)

    let pillText = NSMutableAttributedString()
    pillText.append(NSAttributedString(
        string: "⌘ ⌃ V",
        attributes: [
            .font: keyFont,
            ctColorKey: keyColor.cgColor,
        ]
    ))
    pillText.append(NSAttributedString(
        string: "   to summon clipm",
        attributes: [
            .font: hintFont,
            ctColorKey: hintColor.cgColor,
        ]
    ))

    let pillLine = CTLineCreateWithAttributedString(pillText)
    let pillBounds = CTLineGetBoundsWithOptions(pillLine, .useGlyphPathBounds)
    let pillHeight: CGFloat = 30
    let pillWidth = ceil(pillBounds.width) + 32
    let pillCenterY = yFromTop(362)
    let pillRect = NSRect(
        x: (layoutWidth - pillWidth) / 2.0,
        y: pillCenterY - pillHeight / 2.0,
        width: pillWidth,
        height: pillHeight
    )

    let pillPath = NSBezierPath(roundedRect: pillRect, xRadius: pillHeight / 2.0, yRadius: pillHeight / 2.0)
    NSColor(srgbRed: 0.095, green: 0.11, blue: 0.145, alpha: 0.94).setFill()
    pillPath.fill()
    NSColor(srgbRed: 0.22, green: 0.26, blue: 0.33, alpha: 0.9).setStroke()
    pillPath.lineWidth = 1.0
    pillPath.stroke()

    cg.saveGState()
    cg.textMatrix = .identity
    cg.textPosition = CGPoint(
        x: pillRect.midX - pillBounds.midX,
        y: pillRect.midY - pillBounds.midY
    )
    CTLineDraw(pillLine, cg)
    cg.restoreGState()

    ctx.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    guard let pngData = rep.representation(using: .png, properties: [:]) else {
        fatalError("Failed to encode PNG")
    }
    try! pngData.write(to: URL(fileURLWithPath: outputPath))
}

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
renderBackground(scale: 1.0, outputPath: "\(outDir)/dmg_background.png")
renderBackground(scale: 2.0, outputPath: "\(outDir)/dmg_background@2x.png")
print("Rendered native Apple SF Pro / SF Symbols DMG backgrounds (1x & 2x) to \(outDir)")
