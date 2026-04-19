#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class RuntimeSettingsSummaryBuilderTests: XCTestCase {
    func testBuildIncludesKeySettingsLines() {
        let input = RuntimeSettingsSummaryInput(
            selectedProfileRawValue: "kalihBoxWhite",
            sound: SoundSettings(
                volume: 0.75,
                variation: 0.3,
                pitchVariation: 0.22,
                pressLevel: 1.0,
                releaseLevel: 0.65,
                spaceLevel: 1.1,
                stackModeEnabled: false,
                limiterEnabled: true,
                limiterDrive: 1.2,
                minInterKeyGapMs: 14,
                releaseDuckingStrength: 0.72,
                releaseDuckingWindowMs: 92,
                releaseTailTightness: 0.38
            ),
            compensation: CompensationSettings(
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
                strictVolumeNormalizationEnabled: false
            ),
            typingAdaptiveEnabled: true,
            system: SystemSettings(
                launchAtLogin: false,
                autoOutputPresetEnabled: true,
                perDeviceSoundProfileEnabled: true,
                appearanceModeRawValue: "system"
            )
        )

        let lines = RuntimeSettingsSummaryBuilder.build(input)

        XCTAssertTrue(lines.contains("- profile=kalihBoxWhite"))
        XCTAssertTrue(lines.contains("- volume=0.750"))
        XCTAssertTrue(lines.contains("- dynamicCompensationEnabled=true"))
        XCTAssertTrue(lines.contains("- typingAdaptiveEnabled=true"))
        XCTAssertTrue(lines.contains("- perDeviceSoundProfileEnabled=true"))
    }
}
#endif
