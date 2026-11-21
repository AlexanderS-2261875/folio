// Draws Folio's app icon into an .iconset. Usage: swift make-icon.swift <out.iconset>
import AppKit

let out = URL(fileURLWithPath: CommandLine.arguments[1])
try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)

func draw(_ px: Int) -> Data {
    let s = CGFloat(px)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    // Squircle tile
    let inset = s * 0.1
    let tile = NSRect(x: inset, y: inset, width: s - 2 * inset, height: s - 2 * inset)
    let shape = NSBezierPath(roundedRect: tile, xRadius: tile.width * 0.225, yRadius: tile.width * 0.225)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = .black.withAlphaComponent(0.25)
    shadow.shadowBlurRadius = s * 0.025
    shadow.shadowOffset = NSSize(width: 0, height: -s * 0.01)
    shadow.set()
    NSColor(srgbRed: 0.98, green: 0.97, blue: 0.95, alpha: 1).setFill()
    shape.fill()
    NSGraphicsContext.restoreGraphicsState()
    NSGradient(starting: NSColor(srgbRed: 1, green: 1, blue: 1, alpha: 1),
               ending: NSColor(srgbRed: 0.93, green: 0.92, blue: 0.89, alpha: 1))!.draw(in: shape, angle: -90)

    // Heading bar + text lines
    let left = tile.minX + tile.width * 0.2
    let width = tile.width * 0.6
    NSColor(srgbRed: 0.11, green: 0.11, blue: 0.12, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: left, y: tile.minY + tile.height * 0.66, width: width * 0.62, height: tile.height * 0.075),
                 xRadius: s * 0.012, yRadius: s * 0.012).fill()
    NSColor(srgbRed: 0.55, green: 0.55, blue: 0.58, alpha: 1).setFill()
    for (i, w) in [1.0, 0.92, 1.0, 0.7].enumerated() {
        let y = tile.minY + tile.height * (0.53 - Double(i) * 0.1)
        NSBezierPath(roundedRect: NSRect(x: left, y: y, width: width * w, height: tile.height * 0.035),
                     xRadius: s * 0.008, yRadius: s * 0.008).fill()
    }
    // Ribbon bookmark
    let rx = tile.maxX - tile.width * 0.26, rw = tile.width * 0.11, top = tile.maxY
    let ribbon = NSBezierPath()
    ribbon.move(to: NSPoint(x: rx, y: top))
    ribbon.line(to: NSPoint(x: rx + rw, y: top))
    ribbon.line(to: NSPoint(x: rx + rw, y: top - tile.height * 0.24))
    ribbon.line(to: NSPoint(x: rx + rw / 2, y: top - tile.height * 0.19))
    ribbon.line(to: NSPoint(x: rx, y: top - tile.height * 0.24))
    ribbon.close()
    NSColor(srgbRed: 0.04, green: 0.4, blue: 0.85, alpha: 1).setFill()
    ribbon.fill()

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for base in [16, 32, 128, 256, 512] {
    try! draw(base).write(to: out.appendingPathComponent("icon_\(base)x\(base).png"))
    try! draw(base * 2).write(to: out.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}
