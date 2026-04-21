#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class OutputDeviceTransitionRuntimeCoordinatorTests: XCTestCase {
    func testWhenSnapshotRestoredMarksDeviceProfileAndSkipsAutoPreset() {
        let result = SystemAudioPollResult(
            state: .init(
                detectedSystemVolumeAvailable: true,
                detectedSystemVolumePercent: 40,
                lastSystemVolume: 0.4,
                lastOutputDeviceID: 2,
                currentOutputDeviceUID: "new-dev",
                currentOutputDeviceName: "Headphones",
                initialOutputDeviceResolved: true
            ),
            volumeChanged: false,
            availabilityChanged: false,
            deviceChanged: true,
            previousDeviceUID: "prev-dev",
            deviceUID: "new-dev",
            deviceName: "Headphones",
            isInitialProbe: false
        )

        var calls: [String] = []
        let outcome = OutputDeviceTransitionRuntimeCoordinator.handle(
            result: result,
            perDeviceSoundProfileEnabled: true,
            hasPersistedPrimarySettings: true,
            dependencies: .init(
                saveSnapshot: { uid in calls.append("save:\(uid)") },
                loadBoost: { uid in
                    calls.append("boost:\(uid)")
                    return 1.7
                },
                rebuildAudioGraph: { calls.append("rebuild") },
                restoreSnapshot: { uid in
                    calls.append("restore:\(uid)")
                    return true
                },
                applyAutoPreset: { uid, _ in calls.append("preset:\(uid)") }
            )
        )

        XCTAssertEqual(outcome.currentOutputDeviceBoost, 1.7, accuracy: 0.0001)
        XCTAssertEqual(outcome.statusLabel, "Профиль устройства")
        XCTAssertEqual(calls, ["save:prev-dev", "boost:new-dev", "rebuild", "restore:new-dev", "save:new-dev"])
    }

    func testWhenNoSnapshotFallsBackToAutoPreset() {
        let result = SystemAudioPollResult(
            state: .init(
                detectedSystemVolumeAvailable: true,
                detectedSystemVolumePercent: 55,
                lastSystemVolume: 0.55,
                lastOutputDeviceID: 3,
                currentOutputDeviceUID: "new-dev",
                currentOutputDeviceName: "MacBook Pro Speakers",
                initialOutputDeviceResolved: true
            ),
            volumeChanged: false,
            availabilityChanged: false,
            deviceChanged: true,
            previousDeviceUID: "old-dev",
            deviceUID: "new-dev",
            deviceName: "MacBook Pro Speakers",
            isInitialProbe: false
        )

        var calls: [String] = []
        let outcome = OutputDeviceTransitionRuntimeCoordinator.handle(
            result: result,
            perDeviceSoundProfileEnabled: true,
            hasPersistedPrimarySettings: true,
            dependencies: .init(
                saveSnapshot: { uid in calls.append("save:\(uid)") },
                loadBoost: { _ in 1.0 },
                rebuildAudioGraph: { calls.append("rebuild") },
                restoreSnapshot: { uid in
                    calls.append("restore:\(uid)")
                    return false
                },
                applyAutoPreset: { uid, _ in calls.append("preset:\(uid)") }
            )
        )

        XCTAssertEqual(outcome.statusLabel, "Сохранённые настройки")
        XCTAssertTrue(calls.contains("preset:new-dev"))
    }

    func testWhenPerDeviceProfileDisabledSkipsSnapshotAndUsesAutoPresetFlow() {
        let result = SystemAudioPollResult(
            state: .init(
                detectedSystemVolumeAvailable: true,
                detectedSystemVolumePercent: 50,
                lastSystemVolume: 0.5,
                lastOutputDeviceID: 7,
                currentOutputDeviceUID: "new-dev",
                currentOutputDeviceName: "External Headphones",
                initialOutputDeviceResolved: true
            ),
            volumeChanged: false,
            availabilityChanged: false,
            deviceChanged: true,
            previousDeviceUID: "old-dev",
            deviceUID: "new-dev",
            deviceName: "External Headphones",
            isInitialProbe: false
        )

        var calls: [String] = []
        let outcome = OutputDeviceTransitionRuntimeCoordinator.handle(
            result: result,
            perDeviceSoundProfileEnabled: false,
            hasPersistedPrimarySettings: true,
            dependencies: .init(
                saveSnapshot: { uid in calls.append("save:\(uid)") },
                loadBoost: { uid in
                    calls.append("boost:\(uid)")
                    return 0.9
                },
                rebuildAudioGraph: { calls.append("rebuild") },
                restoreSnapshot: { uid in
                    calls.append("restore:\(uid)")
                    return true
                },
                applyAutoPreset: { uid, _ in calls.append("preset:\(uid)") }
            )
        )

        XCTAssertEqual(outcome.currentOutputDeviceBoost, 0.9, accuracy: 0.0001)
        XCTAssertEqual(outcome.statusLabel, "Сохранённые настройки")
        XCTAssertEqual(calls, ["boost:new-dev", "rebuild", "preset:new-dev"])
    }

    func testInitialProbeWithPersistedSettingsSkipsAutoPresetAndMarksSavedSettings() {
        let result = SystemAudioPollResult(
            state: .init(
                detectedSystemVolumeAvailable: true,
                detectedSystemVolumePercent: 34,
                lastSystemVolume: 0.34,
                lastOutputDeviceID: 101,
                currentOutputDeviceUID: "initial-dev",
                currentOutputDeviceName: "Built-in Output",
                initialOutputDeviceResolved: true
            ),
            volumeChanged: false,
            availabilityChanged: false,
            deviceChanged: true,
            previousDeviceUID: "",
            deviceUID: "initial-dev",
            deviceName: "Built-in Output",
            isInitialProbe: true
        )

        var calls: [String] = []
        let outcome = OutputDeviceTransitionRuntimeCoordinator.handle(
            result: result,
            perDeviceSoundProfileEnabled: true,
            hasPersistedPrimarySettings: true,
            dependencies: .init(
                saveSnapshot: { uid in calls.append("save:\(uid)") },
                loadBoost: { uid in
                    calls.append("boost:\(uid)")
                    return 1.0
                },
                rebuildAudioGraph: { calls.append("rebuild") },
                restoreSnapshot: { uid in
                    calls.append("restore:\(uid)")
                    return false
                },
                applyAutoPreset: { uid, _ in calls.append("preset:\(uid)") }
            )
        )

        XCTAssertEqual(outcome.statusLabel, "Сохранённые настройки")
        XCTAssertEqual(calls, ["boost:initial-dev", "rebuild", "restore:initial-dev", "save:initial-dev"])
        XCTAssertFalse(calls.contains("preset:initial-dev"))
    }
}
#endif
