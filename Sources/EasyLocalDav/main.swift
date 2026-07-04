import AppKit

private let app = NSApplication.shared
private let appDelegate = AppDelegate()

app.delegate = appDelegate
app.setActivationPolicy(.accessory)
app.finishLaunching()
app.run()
