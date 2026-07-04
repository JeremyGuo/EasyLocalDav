import AppKit

enum StatusIconFactory {
    static func image(for health: AppHealth) -> NSImage {
        let size = NSSize(width: 22, height: 22)
        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }

        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()

        let tab = NSBezierPath()
        tab.move(to: NSPoint(x: 3.2, y: 15.7))
        tab.line(to: NSPoint(x: 8.2, y: 15.7))
        tab.line(to: NSPoint(x: 10.0, y: 17.5))
        tab.line(to: NSPoint(x: 15.3, y: 17.5))
        tab.line(to: NSPoint(x: 15.3, y: 12.8))
        tab.line(to: NSPoint(x: 3.2, y: 12.8))
        tab.close()

        let folderBody = NSBezierPath(roundedRect: NSRect(x: 2.8, y: 5.2, width: 16.4, height: 10.6), xRadius: 2.6, yRadius: 2.6)
        let folderGradient = NSGradient(colors: [
            NSColor(calibratedRed: 0.09, green: 0.78, blue: 0.58, alpha: 1),
            NSColor(calibratedRed: 0.12, green: 0.45, blue: 0.92, alpha: 1)
        ])!
        folderGradient.draw(in: tab, angle: -35)
        folderGradient.draw(in: folderBody, angle: -35)

        NSColor(calibratedWhite: 1, alpha: 0.82).setStroke()
        folderBody.lineWidth = 1.2
        folderBody.stroke()

        let connector = NSBezierPath()
        connector.lineWidth = 1.35
        connector.lineJoinStyle = .round
        connector.lineCapStyle = .round
        NSColor(calibratedWhite: 1, alpha: 0.92).setStroke()
        connector.move(to: NSPoint(x: 7.0, y: 10.3))
        connector.line(to: NSPoint(x: 15.0, y: 10.3))
        connector.move(to: NSPoint(x: 11.0, y: 13.0))
        connector.line(to: NSPoint(x: 11.0, y: 7.5))
        connector.stroke()

        let dotColor: NSColor
        switch health {
        case .empty, .stopped:
            dotColor = .systemGray
        case .running:
            dotColor = .systemGreen
        case .partialFailure:
            dotColor = .systemOrange
        }
        NSColor.windowBackgroundColor.setFill()
        NSBezierPath(ovalIn: NSRect(x: 13.2, y: 2.8, width: 7.2, height: 7.2)).fill()
        dotColor.setFill()
        NSBezierPath(ovalIn: NSRect(x: 14.2, y: 3.8, width: 5.2, height: 5.2)).fill()

        image.isTemplate = false
        return image
    }
}
