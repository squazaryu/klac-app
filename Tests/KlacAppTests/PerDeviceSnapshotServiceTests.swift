#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class PerDeviceSnapshotServiceTests: XCTestCase {
    private func makeDefaults() -> UserDefaults {
        let suite = "klac.tests.perdevice.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    private func makeDTO(boost: Double = 1.3) -> DeviceSoundStateDTO {
        DeviceSoundStateDTO(
            volume: 0.8,
            variation: 0.35,
            pitchVariation: 0.25,
            pressLevel: 1.2,
            releaseLevel: 0.7,
            spaceLevel: 1.1,
            levelMacLowMid: 0.45,
            levelKbdLowMid: 1.3,
            levelMacHighMid: 0.8,
            levelKbdHighMid: 0.7,
            stackModeEnabled: true,
            limiterEnabled: true,
            limiterDrive: 1.4,
            minInterKeyGapMs: 12,
            releaseDuckingStrength: 0.7,
            releaseDuckingWindowMs: 90,
            releaseTailTightness: 0.4,
            currentOutputDeviceBoost: boost
        )
    }

    func testSaveSnapshotPersistsSnapshotMap() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)
        var service = PerDeviceSnapshotService(settingsStore: store, snapshots: [:], boosts: [:])

        service.saveSnapshot(deviceUID: "dev-1", state: makeDTO())

        XCTAssertTrue(service.snapshotExists(for: "dev-1"))
        let persisted = store.decode([String: DeviceSoundSnapshot].self, forKey: SettingsKeys.perDeviceSoundSnapshots)
        XCTAssertEqual(persisted?["dev-1"]?.volume, 0.8, accuracy: 0.0001)
    }

    func testSetBoostClampsAndPersists() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)
        var service = PerDeviceSnapshotService(settingsStore: store, snapshots: [:], boosts: [:])

        service.setBoost(3.5, for: "dev-2")

        XCTAssertEqual(service.boost(for: "dev-2"), 2.0, accuracy: 0.0001)
        let persisted = store.decode([String: Double].self, forKey: SettingsKeys.outputDeviceBoosts)
        XCTAssertEqual(persisted?["dev-2"], 2.0, accuracy: 0.0001)
    }

    func testRestoreSnapshotReturnsTrueAndAppliesNormalizedDTO() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)
        let snapshot = DeviceSoundSnapshot(
            volume: 1.4,
            variation: -0.5,
            pitchVariation: 2.0,
            pressLevel: 5,
            releaseLevel: -2,
            spaceLevel: 9,
            levelMacLowMid: 0.01,
            levelKbdLowMid: 8,
            levelMacHighMid: 0.99,
            levelKbdHighMid: -1,
            stackModeEnabled: true,
            limiterEnabled: true,
            limiterDrive: 3,
            minInterKeyGapMs: 100,
            releaseDuckingStrength: 3,
            releaseDuckingWindowMs: 5,
            releaseTailTightness: 3,
            currentOutputDeviceBoost: 4
        )
        var service = PerDeviceSnapshotService(
            settingsStore: store,
            snapshots: ["dev-3": snapshot],
            boosts: [:]
        )

        var applied: DeviceSoundStateDTO?
        let restored = service.restoreSnapshot(deviceUID: "dev-3") { dto in
            applied = dto
        }

        XCTAssertTrue(restored)
        XCTAssertNotNil(applied)
        XCTAssertEqual(applied?.volume, 1.0, accuracy: 0.0001)
        XCTAssertEqual(applied?.variation, 0.0, accuracy: 0.0001)
        XCTAssertEqual(applied?.pitchVariation, 0.6, accuracy: 0.0001)
        XCTAssertEqual(applied?.currentOutputDeviceBoost, 2.0, accuracy: 0.0001)
    }

    func testRestoreSnapshotReturnsFalseForMissingUID() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)
        var service = PerDeviceSnapshotService(settingsStore: store, snapshots: [:], boosts: [:])

        let restored = service.restoreSnapshot(deviceUID: "missing") { _ in
            XCTFail("should not be called")
        }

        XCTAssertFalse(restored)
    }

    func testSavePreviousThenRestoreNewDeviceDoesNotOverwrite() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)
        var service = PerDeviceSnapshotService(settingsStore: store, snapshots: [:], boosts: [:])

        service.saveSnapshot(deviceUID: "old", state: makeDTO(boost: 1.1))
        service.saveSnapshot(deviceUID: "new", state: makeDTO(boost: 1.6))

        var applied: DeviceSoundStateDTO?
        _ = service.restoreSnapshot(deviceUID: "new") { dto in
            applied = dto
        }

        XCTAssertEqual(service.snapshots.count, 2)
        XCTAssertEqual(applied?.currentOutputDeviceBoost, 1.6, accuracy: 0.0001)
    }

    func testBackwardCompatibilityDecodesMissingOptionalFields() throws {
        let json = """
        {
          "volume": 0.8,
          "variation": 0.3,
          "pitchVariation": 0.2,
          "pressLevel": 1.0,
          "releaseLevel": 0.6,
          "spaceLevel": 1.1,
          "stackModeEnabled": false,
          "limiterEnabled": true,
          "limiterDrive": 1.2,
          "minInterKeyGapMs": 14.0,
          "releaseDuckingStrength": 0.72,
          "releaseDuckingWindowMs": 92.0,
          "releaseTailTightness": 0.38,
          "currentOutputDeviceBoost": 1.0
        }
        """
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(DeviceSoundSnapshot.self, from: data)

        XCTAssertEqual(decoded.levelMacLowMid, 0.45, accuracy: 0.0001)
        XCTAssertEqual(decoded.levelKbdLowMid, 1.30, accuracy: 0.0001)
        XCTAssertEqual(decoded.levelMacHighMid, 0.80, accuracy: 0.0001)
        XCTAssertEqual(decoded.levelKbdHighMid, 0.70, accuracy: 0.0001)
    }
}
#endif
