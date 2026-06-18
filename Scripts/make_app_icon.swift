#!/usr/bin/env swift
import AppKit
import Foundation

guard CommandLine.arguments.count == 3 else {
    fputs("Usage: make_app_icon.swift <iconset-dir> <icns-output>\n", stderr)
    exit(2)
}

let iconsetURL = URL(fileURLWithPath: CommandLine.arguments[1])
let icnsURL = URL(fileURLWithPath: CommandLine.arguments[2])
try? FileManager.default.removeItem(at: iconsetURL)
try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    defer { image.unlockFocus() }

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let radius = size * 0.219
    let background = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.125, green: 0.839, blue: 0.631, alpha: 1),
        NSColor(calibratedRed: 0.176, green: 0.612, blue: 0.859, alpha: 1),
        NSColor(calibratedRed: 0.192, green: 0.341, blue: 0.835, alpha: 1)
    ])!
    gradient.draw(in: background, angle: -45)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor(calibratedWhite: 0.02, alpha: 0.22)
    shadow.shadowOffset = NSSize(width: 0, height: -size * 0.027)
    shadow.shadowBlurRadius = size * 0.033
    shadow.set()

    let tab = NSBezierPath()
    tab.move(to: NSPoint(x: size * 0.270, y: size * 0.707))
    tab.line(to: NSPoint(x: size * 0.449, y: size * 0.707))
    tab.curve(to: NSPoint(x: size * 0.523, y: size * 0.660), controlPoint1: NSPoint(x: size * 0.478, y: size * 0.707), controlPoint2: NSPoint(x: size * 0.505, y: size * 0.690))
    tab.line(to: NSPoint(x: size * 0.572, y: size * 0.594))
    tab.line(to: NSPoint(x: size * 0.742, y: size * 0.594))
    tab.curve(to: NSPoint(x: size * 0.805, y: size * 0.531), controlPoint1: NSPoint(x: size * 0.777, y: size * 0.594), controlPoint2: NSPoint(x: size * 0.805, y: size * 0.566))
    tab.line(to: NSPoint(x: size * 0.805, y: size * 0.447))
    tab.line(to: NSPoint(x: size * 0.195, y: size * 0.447))
    tab.line(to: NSPoint(x: size * 0.195, y: size * 0.633))
    tab.curve(to: NSPoint(x: size * 0.270, y: size * 0.707), controlPoint1: NSPoint(x: size * 0.195, y: size * 0.674), controlPoint2: NSPoint(x: size * 0.229, y: size * 0.707))
    tab.close()
    NSColor(calibratedWhite: 1, alpha: 0.98).setFill()
    tab.fill()
    NSGraphicsContext.restoreGraphicsState()

    let folderBody = NSBezierPath(roundedRect: NSRect(x: size * 0.195, y: size * 0.195, width: size * 0.610, height: size * 0.410), xRadius: size * 0.105, yRadius: size * 0.105)
    NSColor(calibratedRed: 0.973, green: 0.984, blue: 1.0, alpha: 1).setFill()
    folderBody.fill()

    let inner = NSBezierPath(roundedRect: NSRect(x: size * 0.293, y: size * 0.281, width: size * 0.414, height: size * 0.219), xRadius: size * 0.043, yRadius: size * 0.043)
    NSColor(calibratedRed: 0.918, green: 0.957, blue: 1.0, alpha: 1).setFill()
    inner.fill()

    let connector = NSBezierPath()
    connector.lineWidth = size * 0.033
    connector.lineCapStyle = .round
    connector.lineJoinStyle = .round
    NSColor(calibratedRed: 0.122, green: 0.435, blue: 0.922, alpha: 1).setStroke()
    connector.move(to: NSPoint(x: size * 0.375, y: size * 0.402))
    connector.line(to: NSPoint(x: size * 0.625, y: size * 0.402))
    connector.move(to: NSPoint(x: size * 0.500, y: size * 0.488))
    connector.line(to: NSPoint(x: size * 0.500, y: size * 0.316))
    connector.stroke()

    func drawNode(center: NSPoint, radius: CGFloat, color: NSColor) {
        NSColor(calibratedRed: 0.969, green: 0.984, blue: 1.0, alpha: 1).setFill()
        NSBezierPath(ovalIn: NSRect(x: center.x - radius * 1.20, y: center.y - radius * 1.20, width: radius * 2.40, height: radius * 2.40)).fill()
        color.setFill()
        NSBezierPath(ovalIn: NSRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)).fill()
        NSColor(calibratedRed: 0.914, green: 1.0, blue: 0.965, alpha: 1).setFill()
        NSBezierPath(ovalIn: NSRect(x: center.x - radius * 0.28, y: center.y - radius * 0.28, width: radius * 0.56, height: radius * 0.56)).fill()
    }

    let nodeRadius = size * 0.047
    let green = NSColor(calibratedRed: 0.063, green: 0.725, blue: 0.506, alpha: 1)
    let brightGreen = NSColor(calibratedRed: 0.204, green: 0.780, blue: 0.349, alpha: 1)
    drawNode(center: NSPoint(x: size * 0.375, y: size * 0.402), radius: nodeRadius, color: green)
    drawNode(center: NSPoint(x: size * 0.500, y: size * 0.488), radius: nodeRadius, color: brightGreen)
    drawNode(center: NSPoint(x: size * 0.625, y: size * 0.402), radius: nodeRadius, color: green)

    return image
}

func writePNG(size: CGFloat, fileName: String) throws {
    let image = drawIcon(size: size)
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "EasyLocalDavIcon", code: 1)
    }
    try png.write(to: iconsetURL.appendingPathComponent(fileName))
}

let outputs: [(CGFloat, String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png")
]

for output in outputs {
    try writePNG(size: output.0, fileName: output.1)
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetURL.path, "-o", icnsURL.path]
try process.run()
process.waitUntilExit()
exit(process.terminationStatus)
