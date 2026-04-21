#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class KeyboardCaptureRuntimeCoordinatorTests: XCTestCase {
    func testStartRefreshesStatusAndStartsAudioAndInput() {
        var audioStarts = 0
        var inputStarts = 0

        let outcome = KeyboardCaptureRuntimeCoordinator.start(
            dependencies: .init(
                refreshStatus: { PermissionsStatus(accessibilityGranted: true, inputMonitoringGranted: true) },
                startAudio: { audioStarts += 1 },
                startInputCapture: {
                    inputStarts += 1
                    return true
                }
            )
        )

        XCTAssertTrue(outcome.accessibilityGranted)
        XCTAssertTrue(outcome.inputMonitoringGranted)
        XCTAssertTrue(outcome.capturingKeyboard)
        XCTAssertEqual(audioStarts, 1)
        XCTAssertEqual(inputStarts, 1)
    }

    func testRefreshWhenEnabledStartsAudioAndInput() {
        var audioStarts = 0
        var inputStarts = 0

        let outcome = KeyboardCaptureRuntimeCoordinator.refresh(
            promptIfNeeded: true,
            isEnabled: true,
            currentCapturingKeyboard: false,
            dependencies: .init(
                refreshStatus: { prompt in
                    XCTAssertTrue(prompt)
                    return PermissionsStatus(accessibilityGranted: true, inputMonitoringGranted: false)
                },
                startAudio: { audioStarts += 1 },
                startInputCapture: {
                    inputStarts += 1
                    return true
                }
            )
        )

        XCTAssertTrue(outcome.accessibilityGranted)
        XCTAssertFalse(outcome.inputMonitoringGranted)
        XCTAssertTrue(outcome.capturingKeyboard)
        XCTAssertEqual(audioStarts, 1)
        XCTAssertEqual(inputStarts, 1)
    }

    func testRefreshWhenDisabledPreservesCaptureStateAndSkipsStart() {
        var audioStarts = 0
        var inputStarts = 0

        let outcome = KeyboardCaptureRuntimeCoordinator.refresh(
            promptIfNeeded: false,
            isEnabled: false,
            currentCapturingKeyboard: true,
            dependencies: .init(
                refreshStatus: { _ in PermissionsStatus(accessibilityGranted: false, inputMonitoringGranted: false) },
                startAudio: { audioStarts += 1 },
                startInputCapture: {
                    inputStarts += 1
                    return false
                }
            )
        )

        XCTAssertTrue(outcome.capturingKeyboard)
        XCTAssertEqual(audioStarts, 0)
        XCTAssertEqual(inputStarts, 0)
    }

    func testStopCallsBothStopDependencies() {
        var inputStops = 0
        var audioStops = 0

        KeyboardCaptureRuntimeCoordinator.stop(
            dependencies: .init(
                stopInputCapture: { inputStops += 1 },
                stopAudio: { audioStops += 1 }
            )
        )

        XCTAssertEqual(inputStops, 1)
        XCTAssertEqual(audioStops, 1)
    }
}
#endif
