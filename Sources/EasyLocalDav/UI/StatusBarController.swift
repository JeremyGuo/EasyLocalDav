import AppKit
import Combine

@MainActor
final class StatusBarController: NSObject {
    private let model: AppModel
    private let openWindow: () -> Void
    private let addService: () -> Void
    private let quit: () -> Void
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private var cancellables: Set<AnyCancellable> = []

    init(model: AppModel, openWindow: @escaping () -> Void, addService: @escaping () -> Void, quit: @escaping () -> Void) {
        self.model = model
        self.openWindow = openWindow
        self.addService = addService
        self.quit = quit
        super.init()

        updateStatusImage()
        statusItem.button?.imagePosition = .imageOnly
        statusItem.button?.imageScaling = .scaleProportionallyDown
        statusItem.button?.toolTip = "EasyLocalDav"
        rebuildMenu()

        model.$services
            .combineLatest(model.$runtimeStates)
            .sink { [weak self] _ in
                self?.updateStatusImage()
                self?.rebuildMenu()
            }
            .store(in: &cancellables)
    }

    private func updateStatusImage() {
        statusItem.isVisible = true
        statusItem.button?.image = StatusIconFactory.image(for: model.health)
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        let title = NSMenuItem(title: statusTitle(), action: nil, keyEquivalent: "")
        title.isEnabled = false
        menu.addItem(title)
        menu.addItem(.separator())

        menu.addItem(item("Open EasyLocalDav", action: #selector(openEasyLocalDav)))
        menu.addItem(item("Add Service", action: #selector(addWebDAVService)))
        menu.addItem(item("Start Enabled Services", action: #selector(startEnabledServices)))
        menu.addItem(item("Stop All Services", action: #selector(stopAllServices)))

        if !model.services.isEmpty {
            menu.addItem(.separator())
            for service in model.services {
                let state = model.state(for: service)
                let item = NSMenuItem(title: "\(service.displayName): \(state.label)", action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())
        menu.addItem(item("Quit EasyLocalDav", action: #selector(quitEasyLocalDav), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    private func item(_ title: String, action: Selector, keyEquivalent: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = self
        return item
    }

    private func statusTitle() -> String {
        switch model.health {
        case .empty:
            return "EasyLocalDav: No Services"
        case .stopped:
            return "EasyLocalDav: Stopped"
        case .running:
            return "EasyLocalDav: Running"
        case .partialFailure:
            return "EasyLocalDav: Needs Attention"
        }
    }

    @objc private func openEasyLocalDav() {
        openWindow()
    }

    @objc private func addWebDAVService() {
        addService()
    }

    @objc private func startEnabledServices() {
        model.startEnabledServices()
    }

    @objc private func stopAllServices() {
        model.stopAll(markDisabled: true)
    }

    @objc private func quitEasyLocalDav() {
        quit()
    }
}
