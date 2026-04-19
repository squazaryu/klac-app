#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class UpdateCheckFlowCoordinatorTests: XCTestCase {
    func testRunMapsUpdateResultToPresentation() async {
        let url = URL(string: "https://github.com/squazaryu/klac-app/releases/tag/v2.2.0")!
        let checker = MockUpdateChecker(result: .updateAvailable(latestVersion: "2.2.0", releaseURL: url))
        let coordinator = UpdateCheckFlowCoordinator(updateChecker: checker)

        let presentation = await coordinator.run(currentVersion: "2.1.4", currentBuild: 1)

        XCTAssertEqual(presentation.statusText, "Найдена версия 2.2.0. Открываю релиз...")
        XCTAssertEqual(presentation.action, .openRelease(url: url))
    }

    func testRunMapsThrownErrorToErrorPresentation() async {
        let checker = MockUpdateChecker(error: MockError.network)
        let coordinator = UpdateCheckFlowCoordinator(updateChecker: checker)

        let presentation = await coordinator.run(currentVersion: "2.1.4", currentBuild: 1)

        XCTAssertEqual(presentation.statusText, "Ошибка обновления: network")
        XCTAssertEqual(
            presentation.action,
            .showInfoAlert(title: "Ошибка обновления", message: "network")
        )
    }
}

private enum MockError: LocalizedError {
    case network
    var errorDescription: String? { "network" }
}

private struct MockUpdateChecker: UpdateChecking {
    var result: UpdateCheckResult?
    var error: Error?

    init(result: UpdateCheckResult) {
        self.result = result
        self.error = nil
    }

    init(error: Error) {
        self.result = nil
        self.error = error
    }

    func check(currentVersion _: String, currentBuild _: Int) async throws -> UpdateCheckResult {
        if let error { throw error }
        return result ?? .upToDate(currentVersion: "0.0.0")
    }
}
#endif
