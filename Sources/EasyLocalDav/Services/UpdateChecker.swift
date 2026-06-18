import Foundation

struct AvailableUpdate: Identifiable, Equatable {
    let id = UUID()
    let version: String
    let releaseURL: URL
    let name: String
}

final class UpdateChecker {
    private struct GitHubRelease: Decodable {
        let tagName: String
        let htmlURL: URL
        let name: String?
        let draft: Bool
        let prerelease: Bool

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case htmlURL = "html_url"
            case name
            case draft
            case prerelease
        }
    }

    private let latestReleaseURL = URL(string: "https://api.github.com/repos/jeremyguo/EasyLocalDav/releases/latest")!

    func check() async throws -> AvailableUpdate? {
        var request = URLRequest(url: latestReleaseURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("EasyLocalDav", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw UpdateCheckError.invalidResponse
        }

        let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
        guard !release.draft, !release.prerelease else {
            return nil
        }

        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
        let latestVersion = normalizedVersion(release.tagName)
        guard compareVersions(latestVersion, currentVersion) == .orderedDescending else {
            return nil
        }

        return AvailableUpdate(
            version: latestVersion,
            releaseURL: release.htmlURL,
            name: release.name ?? "EasyLocalDav \(release.tagName)"
        )
    }

    private func normalizedVersion(_ version: String) -> String {
        version.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingPrefix("v")
            .trimmingPrefix("V")
    }

    private func compareVersions(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let left = versionComponents(lhs)
        let right = versionComponents(rhs)
        let count = max(left.count, right.count)

        for index in 0..<count {
            let leftValue = index < left.count ? left[index] : 0
            let rightValue = index < right.count ? right[index] : 0
            if leftValue > rightValue { return .orderedDescending }
            if leftValue < rightValue { return .orderedAscending }
        }

        return .orderedSame
    }

    private func versionComponents(_ version: String) -> [Int] {
        version
            .split { !$0.isNumber }
            .map { Int($0) ?? 0 }
    }
}

enum UpdateCheckError: LocalizedError {
    case invalidResponse

    var errorDescription: String? {
        "Could not check GitHub Releases right now."
    }
}

private extension String {
    func trimmingPrefix(_ prefix: String) -> String {
        hasPrefix(prefix) ? String(dropFirst(prefix.count)) : self
    }
}
