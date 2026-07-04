import AppKit

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var model: AppModel!
    private var statusBarController: StatusBarController!
    private var mainWindowController: MainWindowController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let model = AppModel()
        self.model = model
        self.mainWindowController = MainWindowController(model: model)
        self.statusBarController = StatusBarController(
            model: model,
            openWindow: { [weak self] in self?.mainWindowController.show() },
            addService: { [weak self] in
                let id = self?.model.addService()
                self?.mainWindowController.show(selectedServiceID: id)
            },
            quit: {
                NSApp.terminate(nil)
            }
        )

        model.restoreEnabledServices()
        model.startUpdateChecks()
    }

    func applicationWillTerminate(_ notification: Notification) {
        model.stopAll(markDisabled: false)
    }
}
