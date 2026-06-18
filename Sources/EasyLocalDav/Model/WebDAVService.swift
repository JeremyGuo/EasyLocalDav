import Foundation

struct WebDAVService: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var localPath: String
    var host: String
    var port: Int
    var username: String
    var password: String
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        name: String = "New Service",
        localPath: String = "",
        host: String = "127.0.0.1",
        port: Int = 0,
        username: String = "easylocaldav",
        password: String = "easylocaldav",
        isEnabled: Bool = false
    ) {
        self.id = id
        self.name = name
        self.localPath = localPath
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.isEnabled = isEnabled
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case localPath
        case host
        case port
        case username
        case password
        case isEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "New Service"
        self.localPath = try container.decodeIfPresent(String.self, forKey: .localPath) ?? ""
        self.host = try container.decodeIfPresent(String.self, forKey: .host) ?? "127.0.0.1"
        self.port = try container.decodeIfPresent(Int.self, forKey: .port) ?? 0
        self.username = try container.decodeIfPresent(String.self, forKey: .username) ?? "easylocaldav"
        self.password = try container.decodeIfPresent(String.self, forKey: .password) ?? "easylocaldav"
        self.isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? false
    }

    var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled Service" : trimmed
    }

    var webDAVURL: String? {
        guard port > 0 else { return nil }
        return "http://\(host):\(port)/"
    }
}

enum RuntimeState: Equatable {
    case stopped
    case starting
    case running
    case failed(String)

    var label: String {
        switch self {
        case .stopped:
            return "Stopped"
        case .starting:
            return "Starting"
        case .running:
            return "Running"
        case .failed:
            return "Failed"
        }
    }

    var isActive: Bool {
        switch self {
        case .starting, .running:
            return true
        case .stopped, .failed:
            return false
        }
    }

    var errorMessage: String? {
        if case let .failed(message) = self {
            return message
        }
        return nil
    }
}

enum AppHealth {
    case empty
    case stopped
    case running
    case partialFailure
}
