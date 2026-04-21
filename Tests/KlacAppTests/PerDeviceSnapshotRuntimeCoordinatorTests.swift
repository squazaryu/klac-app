#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class PerDeviceSnapshotRuntimeCoordinatorTests: XCTestCase {
    private func makeStore() -> SettingsStore {
        let suite = "klac.tests.perdevice.runtime.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return SettingsStore(defaults: defaults)
    }

    private func makeSource(boost: Double = 1.4) -> DeviceSoundStateSource {
        DeviceSoundStateSource(
            volume: 0.77,
            variation: 0.31,
            pitchVariation: 0.23,
            pressLevel: 1.08,
            releaseLevel: 0.64,
            spaceLevel: 1.12,
            levelMacLowMid: 0.45,
            levelKbdLowMid: 1.30,
            levelMacHighMid: 0.80,
            levelKbdHighMid: 0.70,
            stackModeEnabled: false,
            limiterEnabled: true,
            limiterDrive: 1.2,
            minInterKeyGapMs: 14,
            releaseDuckingStrength: 0.72,
            releaseDuckingWindowMs: 92,
            releaseTailTightness: 0.38,
            currentOutputDeviceBoost: boost
        )
    }

    func testPersistSnapshotIfNeededRespectsFlagAndPersistsWhenEnabled() {
        let store = makeStore()
        let service = PerDeviceSnapshotService(settingsStore: store, snapshots: [:], boosts: [:])
        var coordinator = PerDeviceSnapshotRuntimeCoordinator(snapshotService: service)

        coordinator.persistSnapshotIfNeeded(
            perDeviceSoundProfileEnabled: false,
            deviceUID: "dev-1",
            source: makeSource()
        )
        XCTAssertNil(
            store.decode([String: DeviceSoundSnapshot].self, forKey: SettingsKeys.perDeviceSoundSnapshots)?["dev-1"]
        )

        coordinator.persistSnapshotIfNeeded(
            perDeviceSoundProfileEnabled: true,
            deviceUID: "dev-1",
            source: makeSource()
        )
        XCTAssertNotNil(
            store.decode([String: DeviceSoundSnapshot].self, forKey: SettingsKeys.perDeviceSoundSnapshots)?["dev-1"]
        )
    }

    func testPersistBoostIfNeededClampsAndStoresBoost() {
        let store = makeStore()
        let service = PerDeviceSnapshotService(settingsStore: store, snapshots: [:], boosts: [:])
        var coordinator = PerDeviceSnapshotRuntimeCoordinator(snapshotService: service)

        coordinator.persistBoostIfNeeded(
            currentOutputDeviceBoost: 3.1,
            deviceUID: "dev-boost"
        )

        XCTAssertEqual(
            coordinator.loadBoost(deviceUID: "dev-boost"),
            2.0,
            accuracy: 0.0001
        )
    }

    func testRestoreSnapshotPatchIfAvailableReturnsPatchWithMappedValues() {
        let store = makeStore()
        let snapshot = DeviceSoundSnapshot(
            volume: 0.2,
            variation: 0.35,
            pitchVariation: 0.1,
            pressLevel: 0.9,
            releaseLevel: 0.6,
            spaceLevel: 1.0,
            levelMacLowMid: 0.45,
            levelKbdLowMid: 1.30,
            levelMacHighMid: 0.8,
            levelKbdHighMid: 0.7,
            stackModeEnabled: true,
            limiterEnabled: true,
            limiterDrive: 1.2,
            minInterKeyGapMs: 10,
            releaseDuckingStrength: 0.6,
            releaseDuckingWindowMs: 80,
            releaseTailTightness: 0.4,
            currentOutputDeviceBoost: 1.5
        )
        let service = PerDeviceSnapshotService(
            settingsStore: store,
            snapshots: ["dev-restore": snapshot],
            boosts: [:]
        )
        let coordinator = PerDeviceSnapshotRuntimeCoordinator(snapshotService: service)

        let patch = coordinator.restoreSnapshotPatchIfAvailable(deviceUID: "dev-restore")

        XCTAssertNotNil(patch)
        XCTAssertEqual(patch?.volume, 0.2, accuracy: 0.0001)
        XCTAssertEqual(patch?.variation, 0.35, accuracy: 0.0001)
        XCTAssertEqual(patch?.currentOutputDeviceBoost, 1.5, accuracy: 0.0001)
    }

    func testRestoreMissingSnapshotDoesNotMutateExistingSnapshot() {
        let store = makeStore()
        let initialSource = makeSource(boost: 1.3)
        let service = PerDeviceSnapshotService(settingsStore: store, snapshots: [:], boosts: [:])
        var coordinator = PerDeviceSnapshotRuntimeCoordinator(snapshotService: service)

        coordinator.persistSnapshotIfNeeded(
            perDeviceSoundProfileEnabled: true,
            deviceUID: "prev-device",
            source: initialSource
        )

        let missingPatch = coordinator.restoreSnapshotPatchIfAvailable(deviceUID: "new-device")
        XCTAssertNil(missingPatch)

        let persisted = store.decode([String: DeviceSoundSnapshot].self, forKey: SettingsKeys.perDeviceSoundSnapshots)
        XCTAssertNotNil(persisted?["prev-device"])
        XCTAssertNil(persisted?["new-device"])
    }

    func testPersistCurrentDeviceStateWhenEnabledStoresBoostAndSnapshot() {
        let store = makeStore()
        let service = PerDeviceSnapshotService(settingsStore: store, snapshots: [:], boosts: [:])
        var coordinator = PerDeviceSnapshotRuntimeCoordinator(snapshotService: service)

        coordinator.persistCurrentDeviceState(
            perDeviceSoundProfileEnabled: true,
            deviceUID: "dev-current",
            currentOutputDeviceBoost: 1.6,
            source: makeSource(boost: 1.6)
        )

        let boosts = store.decode([String: Double].self, forKey: SettingsKeys.outputDeviceBoosts)
        let snapshots = store.decode([String: DeviceSoundSnapshot].self, forKey: SettingsKeys.perDeviceSoundSnapshots)
        XCTAssertEqual(boosts?["dev-current"], 1.6, accuracy: 0.0001)
        XCTAssertNotNil(snapshots?["dev-current"])
    }

    func testPersistCurrentDeviceStateWhenDisabledStoresOnlyBoost() {
        let store = makeStore()
        let service = PerDeviceSnapshotService(settingsStore: store, snapshots: [:], boosts: [:])
        var coordinator = PerDeviceSnapshotRuntimeCoordinator(snapshotService: service)

        coordinator.persistCurrentDeviceState(
            perDeviceSoundProfileEnabled: false,
            deviceUID: "dev-current",
            currentOutputDeviceBoost: 1.7,
            source: makeSource(boost: 1.7)
        )

        let boosts = store.decode([String: Double].self, forKey: SettingsKeys.outputDeviceBoosts)
        let snapshots = store.decode([String: DeviceSoundSnapshot].self, forKey: SettingsKeys.perDeviceSoundSnapshots)
        XCTAssertEqual(boosts?["dev-current"], 1.7, accuracy: 0.0001)
        XCTAssertNil(snapshots?["dev-current"])
    }
}
#endif
