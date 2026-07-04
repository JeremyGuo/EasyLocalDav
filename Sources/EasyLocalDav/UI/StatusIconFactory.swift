import AppKit

enum StatusIconFactory {
    static func image(for _: AppHealth) -> NSImage {
        if let symbol = NSImage(systemSymbolName: "folder", accessibilityDescription: "EasyLocalDav") {
            let configuration = NSImage.SymbolConfiguration(pointSize: 17, weight: .regular)
            let image = symbol.withSymbolConfiguration(configuration) ?? symbol
            image.isTemplate = true
            return image
        }

        let size = NSSize(width: 22, height: 22)
        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }

        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()

        let folder = NSBezierPath()
        folder.lineWidth = 1.8
        folder.lineJoinStyle = .round
        folder.lineCapStyle = .round
        folder.move(to: NSPoint(x: 5.0, y: 5.4))
        folder.line(to: NSPoint(x: 16.9, y: 5.4))
        folder.curve(to: NSPoint(x: 18.3, y: 6.8), controlPoint1: NSPoint(x: 17.7, y: 5.4), controlPoint2: NSPoint(x: 18.3, y: 6.0))
        folder.line(to: NSPoint(x: 18.3, y: 11.8))
        folder.curve(to: NSPoint(x: 16.9, y: 13.2), controlPoint1: NSPoint(x: 18.3, y: 12.6), controlPoint2: NSPoint(x: 17.7, y: 13.2))
        folder.line(to: NSPoint(x: 10.4, y: 13.2))
        folder.line(to: NSPoint(x: 8.8, y: 14.8))
        folder.curve(to: NSPoint(x: 7.7, y: 15.2), controlPoint1: NSPoint(x: 8.5, y: 15.1), controlPoint2: NSPoint(x: 8.1, y: 15.2))
        folder.line(to: NSPoint(x: 5.1, y: 15.2))
        folder.curve(to: NSPoint(x: 3.7, y: 13.8), controlPoint1: NSPoint(x: 4.3, y: 15.2), controlPoint2: NSPoint(x: 3.7, y: 14.6))
        folder.line(to: NSPoint(x: 3.7, y: 6.8))
        folder.curve(to: NSPoint(x: 5.0, y: 5.4), controlPoint1: NSPoint(x: 3.7, y: 6.0), controlPoint2: NSPoint(x: 4.3, y: 5.4))

        NSColor.black.setStroke()
        folder.stroke()

        image.isTemplate = true
        return image
    }
}
