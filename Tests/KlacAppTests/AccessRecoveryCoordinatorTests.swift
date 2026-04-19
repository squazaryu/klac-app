#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class AccessRecoveryCoordinatorTests: XCTestCase {
    func testSchedulePostResetRefreshUsesExpectedDelay() {
        let scheduler = MockRecoveryScheduler()
        let coordinator = AccessRecoveryCoordinator(scheduler: scheduler)
        var refreshCalled = false

        coordinator.schedulePostResetRefresh {
            refreshCalled = true
        }

        XCTAssertEqual(scheduler.delays, [0.6], accuracy: 0.0001)
        XCTAssertFalse(refreshCalled)
        scheduler.runAll()
        XCTAssertTrue(refreshCalled)
    }

    func testScheduleWizardAddsTwoStepsWithExpectedDelays() {
        let scheduler = MockRecoveryScheduler()
        let coordinator = AccessRecoveryCoordinator(scheduler: scheduler)
        var openCalled = false
        var hintCalled = false
        var restartCalled = false

        coordinator.scheduleWizard(
            openSettings: { openCalled = true },
            setHint: { hintCalled = true },
            restart: { restartCalled = true }
        )

        XCTAssertEqual(scheduler.delays, [0.5, 1.1], accuracy: 0.0001)
        scheduler.run(at: 0)
        XCTAssertTrue(openCalled)
        XCTAssertTrue(hintCalled)
        XCTAssertFalse(restartCalled)
        scheduler.run(at: 1)
        XCTAssertTrue(restartCalled)
    }
}

private final class MockRecoveryScheduler: RecoveryScheduling {
    private(set) var delays: [TimeInterval] = []
    private var blocks: [() -> Void] = []

    func schedule(after delay: TimeInterval, _ block: @escaping () -> Void) {
        delays.append(delay)
        blocks.append(block)
    }

    func run(at index: Int) {
        blocks[index]()
    }

    func runAll() {
        blocks.forEach { $0() }
    }
}
#endif
