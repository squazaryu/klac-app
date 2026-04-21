#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class AccessRecoveryRuntimeCoordinatorTests: XCTestCase {
    func testRunResetFlowResetsTCCAndSchedulesRefresh() {
        var resets: [(String, String)] = []
        var openedAX = 0
        var openedInput = 0
        var refreshCalls = 0

        let result = AccessRecoveryRuntimeCoordinator.runResetFlow(
            dependencies: .init(
                resolveBundleID: { "com.test.klac" },
                resetTCC: { service, bundleID in resets.append((service, bundleID)) },
                openAccessibilitySettings: { openedAX += 1 },
                openInputMonitoringSettings: { openedInput += 1 },
                schedulePostResetRefresh: { work in work() },
                refreshStatus: { refreshCalls += 1 }
            )
        )

        XCTAssertEqual(result?.bundleID, "com.test.klac")
        XCTAssertEqual(result?.hint, "Права сброшены. Перезапусти Klac и включи его снова в Универсальном доступе и Мониторинге ввода.")
        XCTAssertEqual(resets.count, 2)
        XCTAssertEqual(openedAX, 1)
        XCTAssertEqual(openedInput, 1)
        XCTAssertEqual(refreshCalls, 1)
    }

    func testRunWizardFlowSchedulesWizardActions() {
        var resetCalls = 0
        var hintValues: [String] = []
        var openCalls = 0
        var restartCalls = 0

        AccessRecoveryRuntimeCoordinator.runWizardFlow(
            dependencies: .init(
                runResetFlow: { resetCalls += 1 },
                setHint: { hintValues.append($0) },
                scheduleWizard: { open, setHint, restart in
                    open()
                    setHint()
                    restart()
                },
                openSettings: { openCalls += 1 },
                restartApplication: { restartCalls += 1 }
            )
        )

        XCTAssertEqual(resetCalls, 1)
        XCTAssertEqual(openCalls, 1)
        XCTAssertEqual(restartCalls, 1)
        XCTAssertEqual(hintValues.last, "Открыл Универсальный доступ и Мониторинг ввода. После перезапуска включи Klac в обоих списках.")
    }
}
#endif
