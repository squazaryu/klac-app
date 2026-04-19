#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class UpdateCheckPresentationCoordinatorTests: XCTestCase {
    func testUpToDatePresentationContainsExpectedTextsAndAlert() {
        let presentation = UpdateCheckPresentationCoordinator.presentable(
            result: .upToDate(currentVersion: "2.1.4"),
            currentVersion: "2.1.4"
        )

        XCTAssertEqual(presentation.statusText, "У вас актуальная версия (2.1.4).")
        XCTAssertEqual(presentation.debugMessage, "Update check: already up to date (2.1.4)")
        XCTAssertEqual(
            presentation.action,
            .showInfoAlert(
                title: "Обновлений нет",
                message: "Текущая версия 2.1.4 уже актуальна."
            )
        )
    }

    func testUpdateAvailablePresentationOpensRelease() {
        let url = URL(string: "https://github.com/squazaryu/klac-app/releases/tag/v2.1.5")!
        let presentation = UpdateCheckPresentationCoordinator.presentable(
            result: .updateAvailable(latestVersion: "2.1.5", releaseURL: url),
            currentVersion: "2.1.4"
        )

        XCTAssertEqual(presentation.statusText, "Найдена версия 2.1.5. Открываю релиз...")
        XCTAssertEqual(presentation.action, .openRelease(url: url))
    }

    func testErrorPresentationContainsErrorMessage() {
        struct TestError: LocalizedError {
            var errorDescription: String? { "network timeout" }
        }
        let presentation = UpdateCheckPresentationCoordinator.presentable(error: TestError())

        XCTAssertEqual(presentation.statusText, "Ошибка обновления: network timeout")
        XCTAssertEqual(presentation.debugMessage, "Update check failed: network timeout")
        XCTAssertEqual(
            presentation.action,
            .showInfoAlert(title: "Ошибка обновления", message: "network timeout")
        )
    }
}
#endif
