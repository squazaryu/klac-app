#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class RuntimeSettingsSummaryMapperTests: XCTestCase {
    func testMapBuildsSummaryInputModels() {
        let source = RuntimeSettingsSummarySource(
            selectedProfileRawValue: "kalihBoxWhite",
            volume: 0.7,
            variation: 0.2,
            pitchVariation: 0.3,
            pressLevel: 1.1,
            releaseLevel: 0.8,
            spaceLevel: 1.2,
            stackModeEnabled: true,
            limiterEnabled: true,
            limiterDrive: 1.4,
            minInterKeyGapMs: 10,
            releaseDuckingStrength: 0.6,
            releaseDuckingWindowMs: 90,
            releaseTailTightness: 0.4,
            levelMacLow: 0.3,
            levelKbdLow: 1.6,
            levelMacLowMid: 0.45,
            levelKbdLowMid: 1.3,
            levelMacMid: 0.6,
            levelKbdMid: 1.0,
            levelMacHighMid: 0.8,
            levelKbdHighMid: 0.7,
            levelMacHigh: 1.0,
            levelKbdHigh: 0.45,
            dynamicCompensationEnabled: true,
            strictVolumeNormalizationEnabled: false,
            typingAdaptiveEnabled: true,
            launchAtLogin: false,
            autoOutputPresetEnabled: true,
            perDeviceSoundProfileEnabled: true,
            appearanceModeRawValue: "system"
        )

        let input = RuntimeSettingsSummaryMapper.map(source)

        XCTAssertEqual(input.selectedProfileRawValue, "kalihBoxWhite")
        XCTAssertEqual(input.sound.volume, 0.7, accuracy: 0.0001)
        XCTAssertEqual(input.sound.limiterDrive, 1.4, accuracy: 0.0001)
        XCTAssertEqual(input.compensation.levelMacHighMid, 0.8, accuracy: 0.0001)
        XCTAssertEqual(input.compensation.dynamicCompensationEnabled, true)
        XCTAssertEqual(input.typingAdaptiveEnabled, true)
        XCTAssertEqual(input.system.autoOutputPresetEnabled, true)
        XCTAssertEqual(input.system.appearanceModeRawValue, "system")
    }
}
#endif
