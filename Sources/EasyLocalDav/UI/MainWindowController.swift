import AppKit
import SwiftUI

final class MainWindowController: NSWindowController {
    private let model: AppModel
    private var selectedServiceID: UUID?

    init(model: AppModel) {
        self.model = model
        let rootView = ContentView(model: model)
        let hostingController = NSHostingController(rootView: rootView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "EasyLocalDav"
        window.setContentSize(NSSize(width: 860, height: 540))
        window.minSize = NSSize(width: 760, height: 460)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.isReleasedWhenClosed = false
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(selectedServiceID: UUID? = nil) {
        if let selectedServiceID {
            NotificationCenter.default.post(name: .selectService, object: selectedServiceID)
        }
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension Notification.Name {
    static let selectService = Notification.Name("EasyLocalDavSelectService")
}
