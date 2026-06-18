import Darwin
import Foundation

final class RcloneProcessManager {
    struct ProcessHandle {
        let process: Process
        let stdoutPipe: Pipe
        let stderrPipe: Pipe
    }

    private var processes: [UUID: ProcessHandle] = [:]
    private let outputLimit = 4_000

    var rcloneURL: URL? {
        if let resourceURL = Bundle.main.resourceURL {
            let bundled = resourceURL.appendingPathComponent("rclone")
            if FileManager.default.isExecutableFile(atPath: bundled.path) {
                return bundled
            }
        }

        for path in ["/opt/homebrew/bin/rclone", "/usr/local/bin/rclone", "/usr/bin/rclone"] {
            if FileManager.default.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }

        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["which", "rclone"]
        task.standardOutput = pipe
        task.standardError = Pipe()
        do {
            try task.run()
            task.waitUntilExit()
            guard task.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let path = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let path, !path.isEmpty, FileManager.default.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        } catch {
            return nil
        }

        return nil
    }

    func start(
        service: WebDAVService,
        onOutput: @escaping (String) -> Void,
        onExit: @escaping (Int32, String) -> Void
    ) throws {
        if let handle = processes[service.id], handle.process.isRunning {
            return
        }

        guard ["127.0.0.1", "0.0.0.0"].contains(service.host) else {
            throw ServiceStartError.invalidHost
        }
        guard (1...65535).contains(service.port) else {
            throw ServiceStartError.invalidPort
        }
        guard FileManager.default.fileExists(atPath: service.localPath, isDirectory: nil) else {
            throw ServiceStartError.missingDirectory
        }
        guard isDirectory(service.localPath) else {
            throw ServiceStartError.notDirectory
        }
        guard isPortAvailable(host: service.host, port: service.port) else {
            throw ServiceStartError.portUnavailable
        }
        guard let rcloneURL else {
            throw ServiceStartError.rcloneMissing
        }

        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        var recentOutput = ""

        process.executableURL = rcloneURL
        var arguments = [
            "serve",
            "webdav",
            "--addr",
            "\(service.host):\(service.port)",
            "--log-level",
            "INFO",
        ]
        let username = service.username.trimmingCharacters(in: .whitespacesAndNewlines)
        if !username.isEmpty {
            arguments.append(contentsOf: ["--user", username, "--pass", service.password])
        }
        arguments.append(service.localPath)
        process.arguments = arguments
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        let appendOutput: (Data) -> Void = { data in
            guard let text = String(data: data, encoding: .utf8), !text.isEmpty else {
                return
            }
            recentOutput += text
            if recentOutput.count > self.outputLimit {
                recentOutput = String(recentOutput.suffix(self.outputLimit))
            }
            onOutput(text)
        }

        stdoutPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            appendOutput(fileHandle.availableData)
        }
        stderrPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            appendOutput(fileHandle.availableData)
        }
        process.terminationHandler = { [weak self] process in
            stdoutPipe.fileHandleForReading.readabilityHandler = nil
            stderrPipe.fileHandleForReading.readabilityHandler = nil
            self?.processes.removeValue(forKey: service.id)
            onExit(process.terminationStatus, recentOutput)
        }

        try process.run()
        processes[service.id] = ProcessHandle(process: process, stdoutPipe: stdoutPipe, stderrPipe: stderrPipe)
    }

    func stop(id: UUID) {
        guard let handle = processes[id] else { return }
        handle.stdoutPipe.fileHandleForReading.readabilityHandler = nil
        handle.stderrPipe.fileHandleForReading.readabilityHandler = nil
        if handle.process.isRunning {
            handle.process.terminate()
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                if handle.process.isRunning {
                    handle.process.interrupt()
                }
            }
        }
        processes.removeValue(forKey: id)
    }

    func stopAll() {
        for id in Array(processes.keys) {
            stop(id: id)
        }
    }

    private func isDirectory(_ path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    private func isPortAvailable(host: String, port: Int) -> Bool {
        let descriptor = socket(AF_INET, SOCK_STREAM, 0)
        guard descriptor >= 0 else { return false }
        defer { close(descriptor) }

        var value: Int32 = 1
        setsockopt(descriptor, SOL_SOCKET, SO_REUSEADDR, &value, socklen_t(MemoryLayout<Int32>.size))

        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = in_port_t(port).bigEndian
        guard inet_pton(AF_INET, host, &address.sin_addr) == 1 else {
            return false
        }

        let result = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { socketAddress in
                bind(descriptor, socketAddress, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        return result == 0
    }
}

enum ServiceStartError: LocalizedError {
    case invalidHost
    case invalidPort
    case missingDirectory
    case notDirectory
    case portUnavailable
    case rcloneMissing

    var errorDescription: String? {
        switch self {
        case .invalidHost:
            return "Host must be 127.0.0.1 or 0.0.0.0."
        case .invalidPort:
            return "Port must be between 1 and 65535."
        case .missingDirectory:
            return "The selected local directory does not exist."
        case .notDirectory:
            return "The selected local path is not a directory."
        case .portUnavailable:
            return "The selected port is already in use."
        case .rcloneMissing:
            return "rclone was not found in the app bundle or on this Mac."
        }
    }
}
