#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class SystemAudioPollRuntimeCoordinatorTests: XCTestCase {
    private func makeState() -> SystemAudioPollState {
        .init(
            detectedSystemVolumeAvailable: true,
            detectedSystemVolumePercent: 40,
            lastSystemVolume: 0.4,
            lastOutputDeviceID: 1,
            currentOutputDeviceUID: "dev-a",
            currentOutputDeviceName: "Device A",
            initialOutputDeviceResolved: true
        )
    }

    func testDeviceChangeCallsTransitionAndDynamicCompensation() {
        var transitionCalls = 0
        var rebuildCalls = 0
        var compensationCalls = 0
        let payload = SystemAudioPollPayload(
            scalar: 0.4,
            deviceID: 2,
            deviceUID: "dev-b",
            deviceName: "Device B"
        )

        let outcome = SystemAudioPollRuntimeCoordinator.handle(
            payload: payload,
            state: makeState(),
            dependencies: .init(
                handleOutputDeviceTransition: { _ in transitionCalls += 1 },
                rebuildAudioGraphAfterAvailabilityChange: { rebuildCalls += 1 },
                updateDynamicCompensation: { compensationCalls += 1 }
            )
        )

        XCTAssertEqual(transitionCalls, 1)
        XCTAssertEqual(rebuildCalls, 0)
        XCTAssertEqual(compensationCalls, 1)
        XCTAssertFalse(outcome.didRebuildForAvailabilityChange)
        XCTAssertEqual(outcome.state.currentOutputDeviceUID, "dev-b")
    }

    func testAvailabilityOnlyChangeRebuildsGraphAndUpdatesCompensation() {
        var transitionCalls = 0
        var rebuildCalls = 0
        var compensationCalls = 0
        var state = makeState()
        state.detectedSystemVolumeAvailable = false
        let payload = SystemAudioPollPayload(
            scalar: 0.4,
            deviceID: 1,
            deviceUID: "dev-a",
            deviceName: "Device A"
        )

        let outcome = SystemAudioPollRuntimeCoordinator.handle(
            payload: payload,
            state: state,
            dependencies: .init(
                handleOutputDeviceTransition: { _ in transitionCalls += 1 },
                rebuildAudioGraphAfterAvailabilityChange: { rebuildCalls += 1 },
                updateDynamicCompensation: { compensationCalls += 1 }
            )
        )

        XCTAssertEqual(transitionCalls, 0)
        XCTAssertEqual(rebuildCalls, 1)
        XCTAssertEqual(compensationCalls, 1)
        XCTAssertTrue(outcome.didRebuildForAvailabilityChange)
    }
}
#endif
