import AppKit

// Original vector icon, rasterized at standard macOS icon sizes during packaging.
let output = CommandLine.arguments[1]
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                      bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                      isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        let transform = NSAffineTransform()
        transform.scale(by: CGFloat(pixels) / 1024)
        transform.concat()
        NSColor(calibratedRed: 0.97, green: 0.94, blue: 0.88, alpha: 1).setFill()
        NSBezierPath(roundedRect: NSRect(x: 64, y: 64, width: 896, height: 896), xRadius: 200, yRadius: 200).fill()
        NSColor(calibratedRed: 0.88, green: 0.39, blue: 0.32, alpha: 1).setFill()
        NSBezierPath(ovalIn: NSRect(x: 237, y: 230, width: 550, height: 520)).fill()
        NSColor(calibratedRed: 0.42, green: 0.58, blue: 0.36, alpha: 1).setFill()
        NSBezierPath(ovalIn: NSRect(x: 340, y: 705, width: 190, height: 100)).fill()
        NSBezierPath(ovalIn: NSRect(x: 508, y: 720, width: 165, height: 110)).fill()
        NSColor(calibratedRed: 0.24, green: 0.23, blue: 0.21, alpha: 1).setFill()
        for x in [407, 587] { NSBezierPath(ovalIn: NSRect(x: x, y: 478, width: 32, height: 44)).fill() }
        let smile = NSBezierPath()
        smile.move(to: NSPoint(x: 480, y: 429))
        smile.curve(to: NSPoint(x: 544, y: 429), controlPoint1: NSPoint(x: 497, y: 400), controlPoint2: NSPoint(x: 527, y: 400))
        smile.lineWidth = 12
        smile.lineCapStyle = .round
        NSColor(calibratedRed: 0.24, green: 0.23, blue: 0.21, alpha: 1).setStroke()
        smile.stroke()
        NSGraphicsContext.restoreGraphicsState()
        let suffix = scale == 2 ? "@2x" : ""
        let url = URL(fileURLWithPath: output).appendingPathComponent("icon_\(size)x\(size)\(suffix).png")
        try bitmap.representation(using: .png, properties: [:])!.write(to: url)
    }
}
