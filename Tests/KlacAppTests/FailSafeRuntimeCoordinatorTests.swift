#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class FailSafeRuntimeCoordinatorTests: XCTestCase {
    func testRunPerformsResetRecoveryAndAudioFailSafeWhenPlanRequires() {
        var resetCalls = 0
        var recoverCalls = 0
        var audioCalls = 0

        let outcome = FailSafeRuntimeCoordinator.run(
            input: .init(
                now: 100,
                resetThreshold: 6,
                isEnabled: true,
                currentlyCapturingKeyboard: false,
                accessibilityGranted: true,
                inputMonitoringGranted: true
            ),
            dependencies: .init(
                resetStuckPollIfNeeded: { now, threshold in
                    XCTAssertEqual(now, 100, accuracy: 0.0001)
                    XCTAssertEqual(threshold, 6, accuracy: 0.0001)
                    resetCalls += 1
                    return true
                },
                recoverKeyboardCaptureIfNeeded: { isEnabled, accessibilityGranted, inputMonitoringGranted, currentlyCapturing in
                    XCTAssertTrue(isEnabled)
                    XCTAssertTrue(accessibilityGranted)
                    XCTAssertTrue(inputMonitoringGranted)
                    XCTAssertFalse(currentlyCapturing)
                    recoverCalls += 1
                    return true
                },
                runAudioEngineFailSafe: {
                    audioCalls += 1
                }
            )
        )

        XCTAssertTrue(outcome.didResetStuckPoll)
        XCTAssertEqual(outcome.recoveredKeyboardCapture, true)
        XCTAssertEqual(resetCalls, 1)
        XCTAssertEqual(recoverCalls, 1)
        XCTAssertEqual(audioCalls, 1)
    }

    func testRunSkipsRecoveryWhenPlanDoesNotRequire() {
        var recoverCalls = 0

        let outcome = FailSafeRuntimeCoordinator.run(
            input: .init(
                now: 10,
                resetThreshold: 6,
                isEnabled: false,
                currentlyCapturingKeyboard: false,
                accessibilityGranted: false,
                inputMonitoringGranted: false
            ),
            dependencies: .init(
                resetStuckPollIfNeeded: { _, _ in false },
                recoverKeyboardCaptureIfNeeded: { _, _, _, _ in
                    recoverCalls += 1
                    return false
                },
                runAudioEngineFailSafe: {}
            )
        )

        XCTAssertFalse(outcome.didResetStuckPoll)
        XCTAssertNil(outcome.recoveredKeyboardCapture)
        XCTAssertEqual(recoverCalls, 0)
    }
}
#endif
