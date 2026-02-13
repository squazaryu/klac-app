import AppKit

let size: CGFloat = 1024
let rect = NSRect(x: 0, y: 0, width: size, height: size)

let image = NSImage(size: rect.size)
image.lockFocus()

NSGraphicsContext.current?.imageInterpolation = .high

let glassRect = NSRect(x: 110, y: 140, width: 804, height: 804)
let rounded = NSBezierPath(roundedRect: glassRect, xRadius: 180, yRadius: 180)

let gradient = NSGradient(colors: [
    NSColor(calibratedWhite: 1.0, alpha: 0.76),
    NSColor(calibratedRed: 0.85, green: 0.93, blue: 1.0, alpha: 0.62),
    NSColor(calibratedRed: 0.73, green: 0.83, blue: 0.98, alpha: 0.56)
])!
gradient.draw(in: rounded, angle: 90)

NSColor.white.withAlphaComponent(0.62).setStroke()
rounded.lineWidth = 24
rounded.stroke()

let inner = NSBezierPath(roundedRect: glassRect.insetBy(dx: 34, dy: 34), xRadius: 148, yRadius: 148)
NSColor(calibratedWhite: 1.0, alpha: 0.18).setStroke()
inner.lineWidth = 6
inner.stroke()

let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center
let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 410, weight: .bold),
    .foregroundColor: NSColor(calibratedRed: 0.08, green: 0.17, blue: 0.37, alpha: 0.95),
    .paragraphStyle: paragraph
]

let text = NSAttributedString(string: "K", attributes: attrs)
let textRect = NSRect(x: 0, y: 260, width: size, height: 520)
text.draw(in: textRect)

image.unlockFocus()

let data = image.tiffRepresentation!
let bitmap = NSBitmapImageRep(data: data)!
let pngData = bitmap.representation(using: .png, properties: [:])!

let output = URL(fileURLWithPath: "dist/AppIcon-1024.png")
try FileManager.default.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)
try pngData.write(to: output)
print("Generated \(output.path)")
