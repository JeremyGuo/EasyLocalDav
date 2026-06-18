import Foundation

final class ConfigStore {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileManager: FileManager = .default) {
        let supportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = supportDirectory.appendingPathComponent("EasyLocalDav", isDirectory: true)
        self.fileURL = appDirectory.appendingPathComponent("config.json")

        self.encoder = JSONEncoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601

        try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
    }

    func load() -> AppConfig {
        guard let data = try? Data(contentsOf: fileURL) else {
            return .empty
        }

        do {
            return try decoder.decode(AppConfig.self, from: data)
        } catch {
            return .empty
        }
    }

    func save(_ config: AppConfig) {
        do {
            let data = try encoder.encode(config)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            NSLog("EasyLocalDav failed to save config: \(error.localizedDescription)")
        }
    }
}
