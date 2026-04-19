#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class FailSafeTickCoordinatorTests: XCTestCase {
    func testDisabledServiceSkipsRecoveryAndAudioFailSafe() {
        let plan = FailSafeTickCoordinator.makePlan(
            isEnabled: false,
            currentlyCapturingKeyboard: false,
            accessibilityGranted: true,
            inputMonitoringGranted: true
        )

        XCTAssertFalse(plan.shouldAttemptKeyboardRecovery)
        XCTAssertFalse(plan.shouldRunAudioEngineFailSafe)
    }

    func testEnabledAndNotCapturingWithPermissionsAttemptsRecovery() {
        let plan = FailSafeTickCoordinator.makePlan(
            isEnabled: true,
            currentlyCapturingKeyboard: false,
            accessibilityGranted: true,
            inputMonitoringGranted: true
        )

        XCTAssertTrue(plan.shouldAttemptKeyboardRecovery)
        XCTAssertTrue(plan.shouldRunAudioEngineFailSafe)
    }

    func testEnabledButMissingPermissionsSkipsRecoveryKeepsAudioFailSafe() {
        let plan = FailSafeTickCoordinator.makePlan(
            isEnabled: true,
            currentlyCapturingKeyboard: false,
            accessibilityGranted: false,
            inputMonitoringGranted: true
        )

        XCTAssertFalse(plan.shouldAttemptKeyboardRecovery)
        XCTAssertTrue(plan.shouldRunAudioEngineFailSafe)
    }
}
#endif
