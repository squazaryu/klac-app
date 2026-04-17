#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class SettingsRepositoryTests: XCTestCase {
    private func makeDefaults() -> UserDefaults {
        let suite = "klac.tests.settings.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    func testLoadStateUsesDefaultsWhenStorageIsEmpty() {
        let defaults = makeDefaults()
        let repository = SettingsRepository(store: SettingsStore(defaults: defaults))

        let state = repository.loadState()

        XCTAssertEqual(state.volume, 0.75, accuracy: 0.0001)
        XCTAssertEqual(state.selectedProfile, .kalihBoxWhite)
        XCTAssertTrue(state.playKeyUp)
    }

    func testLoadStateComputesMidPointsWhenMissing() {
        let defaults = makeDefaults()
        defaults.set(0.2, forKey: SettingsKeys.levelMacLow)
        defaults.set(0.6, forKey: SettingsKeys.levelMacMid)
        defaults.set(1.4, forKey: SettingsKeys.levelKbdLow)
        defaults.set(1.0, forKey: SettingsKeys.levelKbdMid)

        let repository = SettingsRepository(store: SettingsStore(defaults: defaults))
        let state = repository.loadState()

        XCTAssertEqual(state.levelMacLowMid, 0.4, accuracy: 0.0001)
        XCTAssertEqual(state.levelKbdLowMid, 1.2, accuracy: 0.0001)
    }

    func testLoadStateClampsPitchVariationAndInterKeyGap() {
        let defaults = makeDefaults()
        defaults.set(2.0, forKey: SettingsKeys.pitchVariation)
        defaults.set(120.0, forKey: SettingsKeys.minInterKeyGapMs)

        let repository = SettingsRepository(store: SettingsStore(defaults: defaults))
        let state = repository.loadState()

        XCTAssertEqual(state.pitchVariation, 0.6, accuracy: 0.0001)
        XCTAssertEqual(state.minInterKeyGapMs, 45.0, accuracy: 0.0001)
    }

    func testLoadStateReportsPrimarySettingsPresence() {
        let defaults = makeDefaults()
        defaults.set(0.55, forKey: SettingsKeys.volume)

        let repository = SettingsRepository(store: SettingsStore(defaults: defaults))
        let state = repository.loadState()

        XCTAssertTrue(state.hasPrimaryPersistedSettings)
    }

    func testLoadStateComputesHighMidPointsWhenMissing() {
        let defaults = makeDefaults()
        defaults.set(0.55, forKey: SettingsKeys.levelMacMid)
        defaults.set(0.95, forKey: SettingsKeys.levelMacHigh)
        defaults.set(0.9, forKey: SettingsKeys.levelKbdMid)
        defaults.set(0.5, forKey: SettingsKeys.levelKbdHigh)

        let repository = SettingsRepository(store: SettingsStore(defaults: defaults))
        let state = repository.loadState()

        XCTAssertEqual(state.levelMacHighMid, 0.75, accuracy: 0.0001)
        XCTAssertEqual(state.levelKbdHighMid, 0.7, accuracy: 0.0001)
    }

    func testLoadStateParsesAppearanceAndLevelMode() {
        let defaults = makeDefaults()
        defaults.set(KeyboardSoundService.AppearanceMode.dark.rawValue, forKey: SettingsKeys.appearanceMode)
        defaults.set(KeyboardSoundService.LevelTuningMode.simple.rawValue, forKey: SettingsKeys.levelTuningMode)

        let repository = SettingsRepository(store: SettingsStore(defaults: defaults))
        let state = repository.loadState()

        XCTAssertEqual(state.appearanceMode, .dark)
        XCTAssertEqual(state.levelTuningMode, .simple)
    }
}
#endif
