#if canImport(XCTest)
import CoreAudio
import XCTest
@testable import KlacApp

final class SystemAudioPollCoordinatorTests: XCTestCase {
    func testVolumeAndAvailabilityChangesWhenScalarAppears() {
        let state = SystemAudioPollState(
            detectedSystemVolumeAvailable: false,
            detectedSystemVolumePercent: 0,
            lastSystemVolume: 1.0,
            lastOutputDeviceID: 10,
            currentOutputDeviceUID: "uid-1",
            currentOutputDeviceName: "Old Device",
            initialOutputDeviceResolved: true
        )
        let payload = SystemAudioPollPayload(
            scalar: 0.42,
            deviceID: 10,
            deviceUID: "uid-1",
            deviceName: "Old Device"
        )

        let result = SystemAudioPollCoordinator.process(payload: payload, state: state)

        XCTAssertTrue(result.volumeChanged)
        XCTAssertTrue(result.availabilityChanged)
        XCTAssertFalse(result.deviceChanged)
        XCTAssertEqual(result.state.lastSystemVolume, 0.42, accuracy: 0.0001)
        XCTAssertEqual(result.state.detectedSystemVolumePercent, 42.0, accuracy: 0.0001)
    }

    func testDeviceChangeMarksInitialProbeAndUpdatesState() {
        let state = SystemAudioPollState(
            detectedSystemVolumeAvailable: true,
            detectedSystemVolumePercent: 50,
            lastSystemVolume: 0.5,
            lastOutputDeviceID: 0,
            currentOutputDeviceUID: "",
            currentOutputDeviceName: "System",
            initialOutputDeviceResolved: false
        )
        let payload = SystemAudioPollPayload(
            scalar: nil,
            deviceID: 21,
            deviceUID: "uid-2",
            deviceName: "Headphones"
        )

        let result = SystemAudioPollCoordinator.process(payload: payload, state: state)

        XCTAssertTrue(result.deviceChanged)
        XCTAssertTrue(result.isInitialProbe)
        XCTAssertEqual(result.previousDeviceUID, "")
        XCTAssertEqual(result.state.lastOutputDeviceID, AudioObjectID(21))
        XCTAssertEqual(result.state.currentOutputDeviceUID, "uid-2")
        XCTAssertEqual(result.state.currentOutputDeviceName, "Headphones")
        XCTAssertTrue(result.state.initialOutputDeviceResolved)
    }

    func testNoDeviceChangeAfterInitialResolve() {
        let state = SystemAudioPollState(
            detectedSystemVolumeAvailable: true,
            detectedSystemVolumePercent: 50,
            lastSystemVolume: 0.5,
            lastOutputDeviceID: 21,
            currentOutputDeviceUID: "uid-2",
            currentOutputDeviceName: "Headphones",
            initialOutputDeviceResolved: true
        )
        let payload = SystemAudioPollPayload(
            scalar: nil,
            deviceID: 21,
            deviceUID: "uid-2",
            deviceName: "Headphones"
        )

        let result = SystemAudioPollCoordinator.process(payload: payload, state: state)

        XCTAssertFalse(result.deviceChanged)
        XCTAssertFalse(result.isInitialProbe)
        XCTAssertEqual(result.previousDeviceUID, "uid-2")
    }

    func testShouldApplyAutoPresetRules() {
        XCTAssertFalse(
            SystemAudioPollCoordinator.shouldApplyAutoPreset(
                isInitialProbe: true,
                hasPersistedPrimarySettings: true,
                restoredSnapshot: true
            )
        )
        XCTAssertFalse(
            SystemAudioPollCoordinator.shouldApplyAutoPreset(
                isInitialProbe: true,
                hasPersistedPrimarySettings: true,
                restoredSnapshot: false
            )
        )
        XCTAssertTrue(
            SystemAudioPollCoordinator.shouldApplyAutoPreset(
                isInitialProbe: false,
                hasPersistedPrimarySettings: true,
                restoredSnapshot: false
            )
        )
        XCTAssertTrue(
            SystemAudioPollCoordinator.shouldApplyAutoPreset(
                isInitialProbe: true,
                hasPersistedPrimarySettings: false,
                restoredSnapshot: false
            )
        )
    }
}
#endif
