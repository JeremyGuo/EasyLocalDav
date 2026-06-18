import AppKit

enum StatusIconFactory {
    static func image(for health: AppHealth) -> NSImage {
        let size = NSSize(width: 22, height: 22)
        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }

        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()

        let lineColor = NSColor.labelColor
        lineColor.setStroke()

        let body = NSBezierPath(roundedRect: NSRect(x: 3.5, y: 6.5, width: 15, height: 11), xRadius: 2.2, yRadius: 2.2)
        body.lineWidth = 1.8
        body.stroke()

        let tab = NSBezierPath()
        tab.lineWidth = 1.8
        tab.lineJoinStyle = .round
        tab.lineCapStyle = .round
        tab.move(to: NSPoint(x: 4.2, y: 13.8))
        tab.line(to: NSPoint(x: 8.2, y: 13.8))
        tab.line(to: NSPoint(x: 9.8, y: 15.8))
        tab.line(to: NSPoint(x: 14.5, y: 15.8))
        tab.stroke()

        let dotColor: NSColor
        switch health {
        case .empty, .stopped:
            dotColor = .systemGray
        case .running:
            dotColor = .systemGreen
        case .partialFailure:
            dotColor = .systemOrange
        }
        dotColor.setFill()
        NSBezierPath(ovalIn: NSRect(x: 14.2, y: 3.8, width: 5.2, height: 5.2)).fill()

        image.isTemplate = false
        return image
    }
}
