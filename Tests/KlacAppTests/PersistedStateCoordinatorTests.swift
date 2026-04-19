#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class PersistedStateCoordinatorTests: XCTestCase {
    func testMakePlanMapsSectionsFromRepositoryState() {
        var state = SettingsRepository.State()
        state.isEnabled = false
        state.selectedProfile = .mechvibesHyperXAqua
        state.playKeyUp = false
        state.autoProfileTuningEnabled = false
        state.volume = 0.63
        state.variation = 0.19
        state.pitchVariation = 0.31
        state.stackDensity = 0.72
        state.layerThresholdSlam = 0.05
        state.dynamicCompensationEnabled = true
        state.compensationStrength = 1.4
        state.levelTuningMode = .simple
        state.typingAdaptiveEnabled = true
        state.launchAtLogin = true
        state.autoOutputPresetEnabled = false
        state.perDeviceSoundProfileEnabled = false
        state.appearanceMode = .dark

        let plan = PersistedStateCoordinator.makePlan(from: state)

        XCTAssertEqual(plan.isEnabled, false)
        XCTAssertEqual(plan.sound.selectedProfile, .mechvibesHyperXAqua)
        XCTAssertEqual(plan.sound.playKeyUp, false)
        XCTAssertEqual(plan.sound.autoProfileTuningEnabled, false)
        XCTAssertEqual(plan.sound.soundSettings.volume, 0.63, accuracy: 0.0001)
        XCTAssertEqual(plan.sound.soundSettings.variation, 0.19, accuracy: 0.0001)
        XCTAssertEqual(plan.sound.soundSettings.pitchVariation, 0.31, accuracy: 0.0001)
        XCTAssertEqual(plan.sound.stackDensity, 0.72, accuracy: 0.0001)
        XCTAssertEqual(plan.sound.layerThresholdSlam, 0.05, accuracy: 0.0001)

        XCTAssertEqual(plan.compensation.dynamicCompensationEnabled, true)
        XCTAssertEqual(plan.compensation.compensationStrength, 1.4, accuracy: 0.0001)
        XCTAssertEqual(plan.compensation.levelTuningMode, .simple)
        XCTAssertEqual(plan.compensation.typingAdaptiveEnabled, true)

        XCTAssertEqual(plan.system.launchAtLogin, true)
        XCTAssertEqual(plan.system.autoOutputPresetEnabled, false)
        XCTAssertEqual(plan.system.perDeviceSoundProfileEnabled, false)
        XCTAssertEqual(plan.system.appearanceMode, .dark)
    }
}
#endif
