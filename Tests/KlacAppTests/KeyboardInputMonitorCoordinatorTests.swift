#if canImport(XCTest)
import XCTest
@testable import KlacApp

@MainActor
final class KeyboardInputMonitorCoordinatorTests: XCTestCase {
    func testRecoverIfNeededStartsMonitorWhenAllConditionsAreMet() {
        let monitor = MockKeyboardInputMonitoring()
        let coordinator = KeyboardInputMonitorCoordinator(monitor: monitor)

        let capturing = coordinator.recoverIfNeeded(
            isEnabled: true,
            accessibilityGranted: true,
            inputMonitoringGranted: true,
            currentlyCapturing: false
        )

        XCTAssertTrue(capturing)
        XCTAssertEqual(monitor.startCalls, 1)
    }

    func testRecoverIfNeededDoesNotStartWhenServiceIsDisabled() {
        let monitor = MockKeyboardInputMonitoring()
        let coordinator = KeyboardInputMonitorCoordinator(monitor: monitor)

        let capturing = coordinator.recoverIfNeeded(
            isEnabled: false,
            accessibilityGranted: true,
            inputMonitoringGranted: true,
            currentlyCapturing: false
        )

        XCTAssertFalse(capturing)
        XCTAssertEqual(monitor.startCalls, 0)
    }

    func testRecoverIfNeededDoesNotStartWhenAlreadyCapturing() {
        let monitor = MockKeyboardInputMonitoring()
        let coordinator = KeyboardInputMonitorCoordinator(monitor: monitor)

        let capturing = coordinator.recoverIfNeeded(
            isEnabled: true,
            accessibilityGranted: true,
            inputMonitoringGranted: true,
            currentlyCapturing: true
        )

        XCTAssertTrue(capturing)
        XCTAssertEqual(monitor.startCalls, 0)
    }

    func testRecoverIfNeededDoesNotStartWithoutPermissions() {
        let monitor = MockKeyboardInputMonitoring()
        let coordinator = KeyboardInputMonitorCoordinator(monitor: monitor)

        let noAX = coordinator.recoverIfNeeded(
            isEnabled: true,
            accessibilityGranted: false,
            inputMonitoringGranted: true,
            currentlyCapturing: false
        )
        let noInput = coordinator.recoverIfNeeded(
            isEnabled: true,
            accessibilityGranted: true,
            inputMonitoringGranted: false,
            currentlyCapturing: false
        )

        XCTAssertFalse(noAX)
        XCTAssertFalse(noInput)
        XCTAssertEqual(monitor.startCalls, 0)
    }
}

private final class MockKeyboardInputMonitoring: KeyboardInputMonitoring {
    var onEvent: ((KeyEventType, Int, Bool) -> Void)?
    var startCalls = 0
    var stopCalls = 0

    func start() -> Bool {
        startCalls += 1
        return true
    }

    func stop() {
        stopCalls += 1
    }
}
#endif
