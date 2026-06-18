import Foundation

struct AppConfig: Codable, Equatable {
    var autoRestoreEnabledServices: Bool
    var automaticUpdateChecksEnabled: Bool
    var lastUpdateCheck: Date?
    var services: [WebDAVService]

    static let empty = AppConfig(
        autoRestoreEnabledServices: true,
        automaticUpdateChecksEnabled: true,
        lastUpdateCheck: nil,
        services: []
    )

    enum CodingKeys: String, CodingKey {
        case autoRestoreEnabledServices
        case automaticUpdateChecksEnabled
        case lastUpdateCheck
        case services
    }

    init(
        autoRestoreEnabledServices: Bool,
        automaticUpdateChecksEnabled: Bool,
        lastUpdateCheck: Date?,
        services: [WebDAVService]
    ) {
        self.autoRestoreEnabledServices = autoRestoreEnabledServices
        self.automaticUpdateChecksEnabled = automaticUpdateChecksEnabled
        self.lastUpdateCheck = lastUpdateCheck
        self.services = services
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.autoRestoreEnabledServices = try container.decodeIfPresent(Bool.self, forKey: .autoRestoreEnabledServices) ?? true
        self.automaticUpdateChecksEnabled = try container.decodeIfPresent(Bool.self, forKey: .automaticUpdateChecksEnabled) ?? true
        self.lastUpdateCheck = try container.decodeIfPresent(Date.self, forKey: .lastUpdateCheck)
        self.services = try container.decodeIfPresent([WebDAVService].self, forKey: .services) ?? []
    }
}
