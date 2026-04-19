import Foundation

protocol UpdateChecking {
    func check(currentVersion: String, currentBuild: Int) async throws -> UpdateCheckResult
}

enum UpdateCheckResult: Equatable {
    case upToDate(currentVersion: String)
    case updateAvailable(latestVersion: String, releaseURL: URL)
    case invalidReleaseLink(latestVersion: String)
}

struct UpdateCheckService {
    let fetchLatestRelease: () async throws -> GitHubRelease

    func check(currentVersion: String, currentBuild: Int) async throws -> UpdateCheckResult {
        let release = try await fetchLatestRelease()
        let latestVersion = KlacVersioning.normalizedVersion(fromTag: release.tag_name)
        guard KlacVersioning.isVersion(latestVersion, newerThan: currentVersion, currentBuild: currentBuild) else {
            return .upToDate(currentVersion: currentVersion)
        }
        guard let releaseURL = URL(string: release.html_url) else {
            return .invalidReleaseLink(latestVersion: latestVersion)
        }
        return .updateAvailable(latestVersion: latestVersion, releaseURL: releaseURL)
    }
}

extension UpdateCheckService: UpdateChecking {}
