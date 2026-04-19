#if canImport(XCTest)
import Foundation
import XCTest
@testable import KlacApp

final class SettingsRepositoryTests: XCTestCase {
    private func makeDefaults() -> UserDefaults {
        let suite = "klac.tests.settingsrepo.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    func testLoadStateAppliesClampsAndDerivedMidPoints() {
        let defaults = makeDefaults()
        defaults.set(3.5, forKey: SettingsKeys.levelKbdLow)
        defaults.set(0.4, forKey: SettingsKeys.levelKbdMid)
        defaults.set(0.3, forKey: SettingsKeys.levelKbdHigh)
        defaults.set(0.2, forKey: SettingsKeys.levelMacLow)
        defaults.set(0.8, forKey: SettingsKeys.levelMacMid)
        defaults.set(0.9, forKey: SettingsKeys.levelMacHigh)
        defaults.set(9.0, forKey: SettingsKeys.layerThresholdSlam)
        defaults.set(-5.0, forKey: SettingsKeys.layerThresholdHard)
        defaults.set(99.0, forKey: SettingsKeys.layerThresholdMedium)
        defaults.set(200.0, forKey: SettingsKeys.minInterKeyGapMs)
        defaults.set(-1.0, forKey: SettingsKeys.releaseDuckingStrength)
        defaults.set(999.0, forKey: SettingsKeys.releaseDuckingWindowMs)

        let repository = SettingsRepository(store: SettingsStore(defaults: defaults))
        let state = repository.loadState()

        XCTAssertEqual(state.levelKbdLowMid, 1.95, accuracy: 0.0001)
        XCTAssertEqual(state.levelMacLowMid, 0.5, accuracy: 0.0001)
        XCTAssertEqual(state.levelMacHighMid, 0.85, accuracy: 0.0001)
        XCTAssertEqual(state.layerThresholdSlam, 0.120, accuracy: 0.0001)
        XCTAssertEqual(state.layerThresholdHard, 0.025, accuracy: 0.0001)
        XCTAssertEqual(state.layerThresholdMedium, 0.260, accuracy: 0.0001)
        XCTAssertEqual(state.minInterKeyGapMs, 45, accuracy: 0.0001)
        XCTAssertEqual(state.releaseDuckingStrength, 0, accuracy: 0.0001)
        XCTAssertEqual(state.releaseDuckingWindowMs, 180, accuracy: 0.0001)
    }

    func testLoadStateMigratesLegacySettingsDomainOnce() {
        let defaults = makeDefaults()
        defaults.setPersistentDomain(
            [
                SettingsKeys.volume: 0.66,
                SettingsKeys.selectedProfile: SoundProfile.mechvibesEGOreo.rawValue,
            ],
            forName: "com.tumowuh.klac"
        )

        let repository = SettingsRepository(store: SettingsStore(defaults: defaults))
        let state = repository.loadState()

        XCTAssertEqual(state.volume, 0.66, accuracy: 0.0001)
        XCTAssertEqual(state.selectedProfile, .mechvibesEGOreo)
    }
}
#endif
