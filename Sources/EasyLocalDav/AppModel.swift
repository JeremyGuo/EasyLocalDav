import AppKit
import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published var services: [WebDAVService] {
        didSet { save() }
    }
    @Published var autoRestoreEnabledServices: Bool {
        didSet { save() }
    }
    @Published var automaticUpdateChecksEnabled: Bool {
        didSet {
            save()
            configureUpdateTimer()
        }
    }
    @Published private(set) var runtimeStates: [UUID: RuntimeState] = [:]
    @Published private(set) var launchAtLoginEnabled = false
    @Published var transientError: String?
    @Published var availableUpdate: AvailableUpdate?
    @Published private(set) var isCheckingForUpdates = false

    private let store: ConfigStore
    private let processManager: RcloneProcessManager
    private let launchAtLoginController: LaunchAtLoginController
    private let updateChecker: UpdateChecker
    private var intentionalStops: Set<UUID> = []
    private var lastUpdateCheck: Date?
    private var updateTimer: Timer?

    init(
        store: ConfigStore = ConfigStore(),
        processManager: RcloneProcessManager = RcloneProcessManager(),
        launchAtLoginController: LaunchAtLoginController = LaunchAtLoginController(),
        updateChecker: UpdateChecker = UpdateChecker()
    ) {
        self.store = store
        self.processManager = processManager
        self.launchAtLoginController = launchAtLoginController
        self.updateChecker = updateChecker

        let config = store.load()
        self.services = config.services
        self.autoRestoreEnabledServices = config.autoRestoreEnabledServices
        self.automaticUpdateChecksEnabled = config.automaticUpdateChecksEnabled
        self.lastUpdateCheck = config.lastUpdateCheck
        self.launchAtLoginEnabled = launchAtLoginController.isEnabled

        for service in services {
            runtimeStates[service.id] = .stopped
        }
    }

    var health: AppHealth {
        guard !services.isEmpty else { return .empty }
        if runtimeStates.values.contains(where: {
            if case .failed = $0 { return true }
            return false
        }) {
            return .partialFailure
        }
        if runtimeStates.values.contains(where: { $0 == .running || $0 == .starting }) {
            return .running
        }
        return .stopped
    }

    func state(for service: WebDAVService) -> RuntimeState {
        runtimeStates[service.id] ?? .stopped
    }

    func addService() -> UUID {
        let service = WebDAVService(name: nextDefaultName())
        services.append(service)
        runtimeStates[service.id] = .stopped
        return service.id
    }

    func removeService(id: UUID) {
        stopService(id: id, markDisabled: true)
        services.removeAll { $0.id == id }
        runtimeStates.removeValue(forKey: id)
    }

    func updateService(_ service: WebDAVService) {
        guard let index = services.firstIndex(where: { $0.id == service.id }) else { return }
        services[index] = service
    }

    func setServiceEnabled(id: UUID, enabled: Bool) {
        guard let index = services.firstIndex(where: { $0.id == id }) else { return }
        services[index].isEnabled = enabled
        if enabled {
            startService(id: id)
        } else {
            stopService(id: id, markDisabled: false)
        }
    }

    func startService(id: UUID) {
        guard let index = services.firstIndex(where: { $0.id == id }) else { return }
        let service = services[index]
        runtimeStates[id] = .starting
        intentionalStops.remove(id)

        do {
            try processManager.start(
                service: service,
                onOutput: { [weak self] _ in
                    Task { @MainActor in
                        guard let self else { return }
                        if self.runtimeStates[id] == .starting {
                            self.runtimeStates[id] = .running
                        }
                    }
                },
                onExit: { [weak self] status, output in
                    Task { @MainActor in
                        guard let self else { return }
                        if self.intentionalStops.contains(id) {
                            self.runtimeStates[id] = .stopped
                            self.intentionalStops.remove(id)
                        } else {
                            let message = output.trimmingCharacters(in: .whitespacesAndNewlines)
                            self.runtimeStates[id] = .failed(message.isEmpty ? "rclone exited with status \(status)." : message)
                            if let serviceIndex = self.services.firstIndex(where: { $0.id == id }) {
                                self.services[serviceIndex].isEnabled = false
                            }
                        }
                    }
                }
            )
            services[index].isEnabled = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                guard let self else { return }
                if self.runtimeStates[id] == .starting {
                    self.runtimeStates[id] = .running
                }
            }
        } catch {
            services[index].isEnabled = false
            runtimeStates[id] = .failed(error.localizedDescription)
        }
    }

    func stopService(id: UUID, markDisabled: Bool) {
        intentionalStops.insert(id)
        processManager.stop(id: id)
        runtimeStates[id] = .stopped
        if markDisabled, let index = services.firstIndex(where: { $0.id == id }) {
            services[index].isEnabled = false
        }
    }

    func startEnabledServices() {
        for service in services where service.isEnabled {
            startService(id: service.id)
        }
    }

    func stopAll(markDisabled: Bool) {
        for service in services {
            stopService(id: service.id, markDisabled: markDisabled)
        }
        processManager.stopAll()
    }

    func restoreEnabledServices() {
        guard autoRestoreEnabledServices else { return }
        startEnabledServices()
    }

    func startUpdateChecks() {
        configureUpdateTimer()
        guard automaticUpdateChecksEnabled else { return }
        if shouldCheckForUpdates() {
            checkForUpdates(silent: true)
        }
    }

    func checkForUpdates(silent: Bool) {
        guard !isCheckingForUpdates else { return }
        isCheckingForUpdates = true

        Task {
            do {
                let update = try await updateChecker.check()
                await MainActor.run {
                    self.isCheckingForUpdates = false
                    self.lastUpdateCheck = Date()
                    self.save()
                    if let update {
                        self.availableUpdate = update
                    } else if !silent {
                        self.transientError = "EasyLocalDav is up to date."
                    }
                }
            } catch {
                await MainActor.run {
                    self.isCheckingForUpdates = false
                    self.lastUpdateCheck = Date()
                    self.save()
                    if !silent {
                        self.transientError = error.localizedDescription
                    }
                }
            }
        }
    }

    func openRelease(_ update: AvailableUpdate) {
        NSWorkspace.shared.open(update.releaseURL)
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try launchAtLoginController.setEnabled(enabled)
            launchAtLoginEnabled = launchAtLoginController.isEnabled
        } catch {
            launchAtLoginEnabled = launchAtLoginController.isEnabled
            transientError = error.localizedDescription
        }
    }

    func revealInFinder(path: String) {
        guard !path.isEmpty else { return }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
    }

    private func save() {
        store.save(AppConfig(
            autoRestoreEnabledServices: autoRestoreEnabledServices,
            automaticUpdateChecksEnabled: automaticUpdateChecksEnabled,
            lastUpdateCheck: lastUpdateCheck,
            services: services
        ))
    }

    private func nextDefaultName() -> String {
        let base = "WebDAV Service"
        var candidate = base
        var index = 2
        let existing = Set(services.map(\.name))
        while existing.contains(candidate) {
            candidate = "\(base) \(index)"
            index += 1
        }
        return candidate
    }

    private func shouldCheckForUpdates() -> Bool {
        guard let lastUpdateCheck else { return true }
        return Date().timeIntervalSince(lastUpdateCheck) >= 24 * 60 * 60
    }

    private func configureUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil

        guard automaticUpdateChecksEnabled else { return }
        updateTimer = Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { [weak self] _ in
            guard let model = self else { return }
            Task { @MainActor in
                model.checkForUpdates(silent: true)
            }
        }
    }
}
