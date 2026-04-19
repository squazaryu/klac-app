#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class UpdateCheckActionExecutorTests: XCTestCase {
    func testNilActionDoesNothing() {
        let alert = MockAlert()
        let opener = MockOpener()

        UpdateCheckActionExecutor.execute(nil, alertPresenter: alert, urlOpener: opener)

        XCTAssertEqual(alert.calls, 0)
        XCTAssertEqual(opener.calls, 0)
    }

    func testAlertActionUsesAlertPresenter() {
        let alert = MockAlert()
        let opener = MockOpener()

        UpdateCheckActionExecutor.execute(
            .showInfoAlert(title: "t", message: "m"),
            alertPresenter: alert,
            urlOpener: opener
        )

        XCTAssertEqual(alert.calls, 1)
        XCTAssertEqual(alert.lastTitle, "t")
        XCTAssertEqual(alert.lastMessage, "m")
        XCTAssertEqual(opener.calls, 0)
    }

    func testOpenReleaseActionUsesURLOpener() {
        let alert = MockAlert()
        let opener = MockOpener()
        let url = URL(string: "https://example.com/release")!

        UpdateCheckActionExecutor.execute(
            .openRelease(url: url),
            alertPresenter: alert,
            urlOpener: opener
        )

        XCTAssertEqual(alert.calls, 0)
        XCTAssertEqual(opener.calls, 1)
        XCTAssertEqual(opener.lastURL, url)
    }
}

private final class MockAlert: InfoAlertPresenting {
    var calls = 0
    var lastTitle: String?
    var lastMessage: String?

    func showInfoAlert(title: String, message: String) {
        calls += 1
        lastTitle = title
        lastMessage = message
    }
}

private final class MockOpener: URLOpening {
    var calls = 0
    var lastURL: URL?

    func open(_ url: URL) {
        calls += 1
        lastURL = url
    }
}
#endif
