import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var model: AppModel
    @State private var selectedServiceID: UUID?

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            detail
        }
        .frame(minWidth: 760, minHeight: 460)
        .onAppear {
            if selectedServiceID == nil {
                selectedServiceID = model.services.first?.id
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .selectService)) { notification in
            selectedServiceID = notification.object as? UUID
        }
        .alert("EasyLocalDav", isPresented: transientErrorBinding) {
            Button("OK", role: .cancel) {
                model.transientError = nil
            }
        } message: {
            Text(model.transientError ?? "")
        }
        .alert(item: $model.availableUpdate) { update in
            Alert(
                title: Text("Update Available"),
                message: Text("\(update.name) is available on GitHub Releases."),
                primaryButton: .default(Text("Open Release")) {
                    model.openRelease(update)
                },
                secondaryButton: .cancel(Text("Later"))
            )
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Services")
                    .font(.headline)
                Spacer()
                Button {
                    selectedServiceID = model.addService()
                } label: {
                    TemplateIcon(name: "plus", fallbackSystemName: "plus", size: 15)
                }
                .buttonStyle(.borderless)
                .help("Add service")
            }
            .padding([.horizontal, .top], 14)
            .padding(.bottom, 8)

            List(selection: $selectedServiceID) {
                ForEach(model.services) { service in
                    ServiceRow(service: service, state: model.state(for: service))
                        .tag(service.id)
                }
            }
            .listStyle(.sidebar)

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Toggle("Launch at Login", isOn: Binding(
                    get: { model.launchAtLoginEnabled },
                    set: { model.setLaunchAtLogin($0) }
                ))
                Toggle("Restore Enabled Services", isOn: $model.autoRestoreEnabledServices)
                Toggle("Check for Updates", isOn: $model.automaticUpdateChecksEnabled)
                Button {
                    model.checkForUpdates(silent: false)
                } label: {
                    if model.isCheckingForUpdates {
                        Text("Checking...")
                    } else {
                        Text("Check Now")
                    }
                }
                .disabled(model.isCheckingForUpdates)
            }
            .font(.callout)
            .padding(14)
        }
        .frame(width: 250)
    }

    @ViewBuilder
    private var detail: some View {
        if let selectedServiceID,
           let binding = binding(for: selectedServiceID) {
            ServiceDetailView(service: binding, state: model.state(for: binding.wrappedValue), model: model)
        } else {
            VStack(spacing: 16) {
                TemplateIcon(name: "server", fallbackSystemName: "server.rack", size: 42)
                    .foregroundStyle(.secondary)
                Text("Add a WebDAV service to begin.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Button {
                    selectedServiceID = model.addService()
                } label: {
                    Label("Add Service", systemImage: "plus")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var transientErrorBinding: Binding<Bool> {
        Binding(
            get: { model.transientError != nil },
            set: { if !$0 { model.transientError = nil } }
        )
    }

    private func binding(for id: UUID) -> Binding<WebDAVService>? {
        guard let index = model.services.firstIndex(where: { $0.id == id }) else {
            return nil
        }

        return Binding(
            get: { model.services[index] },
            set: { model.updateService($0) }
        )
    }
}

private struct ServiceRow: View {
    let service: WebDAVService
    let state: RuntimeState

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(service.displayName)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    private var subtitle: String {
        if let url = service.webDAVURL {
            return "\(state.label) - \(url)"
        }
        return "\(state.label) - port required"
    }

    private var color: Color {
        switch state {
        case .stopped:
            return .secondary
        case .starting:
            return .yellow
        case .running:
            return .green
        case .failed:
            return .orange
        }
    }
}

private struct ServiceDetailView: View {
    @Binding var service: WebDAVService
    let state: RuntimeState
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            Form {
                Section {
                    TextField("Name", text: $service.name)

                    Picker("Host", selection: $service.host) {
                        Text("127.0.0.1").tag("127.0.0.1")
                        Text("0.0.0.0").tag("0.0.0.0")
                    }
                    .pickerStyle(.segmented)

                    TextField("Port", text: portBinding)
                        .monospacedDigit()

                    TextField("WebDAV Username", text: $service.username)
                        .textContentType(.username)

                    SecureField("WebDAV Password", text: $service.password)
                        .textContentType(.password)

                    HStack {
                        TextField("Local Directory", text: $service.localPath)
                        Button {
                            chooseDirectory()
                        } label: {
                            Label("Choose", systemImage: "folder")
                        }
                    }
                }

                Section {
                    Toggle("Enabled", isOn: Binding(
                        get: { service.isEnabled },
                        set: { model.setServiceEnabled(id: service.id, enabled: $0) }
                    ))
                    Text("Enabled services start now and are restored when EasyLocalDav launches.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if service.host == "0.0.0.0" {
                    Label("0.0.0.0 can expose this WebDAV server to your local network. Use it only on trusted networks.", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }

                if let error = state.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                        .textSelection(.enabled)
                }

                if let url = service.webDAVURL {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(url)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                            Spacer()
                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(url, forType: .string)
                            } label: {
                                Label("Copy URL", systemImage: "doc.on.doc")
                            }
                        }
                        Text("Zotero username: \(service.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "none" : service.username). Use the configured password shown above.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
            }
            .formStyle(.grouped)
            .disabled(state.isActive)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(service.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(state.label)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if state.isActive {
                Button {
                    model.stopService(id: service.id, markDisabled: true)
                } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .keyboardShortcut(.defaultAction)
            } else {
                Button {
                    model.startService(id: service.id)
                } label: {
                    Label("Start", systemImage: "play.fill")
                }
                .keyboardShortcut(.defaultAction)
            }
            Button(role: .destructive) {
                model.removeService(id: service.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .padding(20)
    }

    private var portBinding: Binding<String> {
        Binding(
            get: {
                service.port == 0 ? "" : String(service.port)
            },
            set: { value in
                let digits = value.filter(\.isNumber)
                if let port = Int(digits) {
                    service.port = port
                } else {
                    service.port = 0
                }
            }
        )
    }

    private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        if panel.runModal() == .OK, let url = panel.url {
            service.localPath = url.path
            if service.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || service.name.hasPrefix("WebDAV Service") {
                service.name = url.lastPathComponent
            }
        }
    }
}
