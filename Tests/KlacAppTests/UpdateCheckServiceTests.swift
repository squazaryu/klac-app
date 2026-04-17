#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class UpdateCheckServiceTests: XCTestCase {
    func testReturnsUpToDateWhenLatestIsNotNewer() async throws {
        let service = UpdateCheckService(fetchLatestRelease: {
            GitHubRelease(tag_name: "v2.1.0", html_url: "https://example.com/release", assets: [])
        })

        let result = try await service.check(currentVersion: "2.1.0", currentBuild: 3)
        XCTAssertEqual(result, .upToDate(currentVersion: "2.1.0"))
    }

    func testReturnsUpdateAvailableWhenVersionIsNewer() async throws {
        let service = UpdateCheckService(fetchLatestRelease: {
            GitHubRelease(tag_name: "v2.1.1", html_url: "https://example.com/release", assets: [])
        })

        let result = try await service.check(currentVersion: "2.1.0", currentBuild: 99)
        XCTAssertEqual(
            result,
            .updateAvailable(latestVersion: "2.1.1", releaseURL: URL(string: "https://example.com/release")!)
        )
    }

    func testReturnsInvalidReleaseLinkForMalformedURL() async throws {
        let service = UpdateCheckService(fetchLatestRelease: {
            GitHubRelease(tag_name: "v2.1.2", html_url: "://bad-url", assets: [])
        })

        let result = try await service.check(currentVersion: "2.1.1", currentBuild: 7)
        XCTAssertEqual(result, .invalidReleaseLink(latestVersion: "2.1.2"))
    }
}
#endif
