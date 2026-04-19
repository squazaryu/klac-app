import Foundation

struct RuntimeSettingsSummarySource {
    let selectedProfileRawValue: String
    let volume: Double
    let variation: Double
    let pitchVariation: Double
    let pressLevel: Double
    let releaseLevel: Double
    let spaceLevel: Double
    let stackModeEnabled: Bool
    let limiterEnabled: Bool
    let limiterDrive: Double
    let minInterKeyGapMs: Double
    let releaseDuckingStrength: Double
    let releaseDuckingWindowMs: Double
    let releaseTailTightness: Double
    let levelMacLow: Double
    let levelKbdLow: Double
    let levelMacLowMid: Double
    let levelKbdLowMid: Double
    let levelMacMid: Double
    let levelKbdMid: Double
    let levelMacHighMid: Double
    let levelKbdHighMid: Double
    let levelMacHigh: Double
    let levelKbdHigh: Double
    let dynamicCompensationEnabled: Bool
    let strictVolumeNormalizationEnabled: Bool
    let typingAdaptiveEnabled: Bool
    let launchAtLogin: Bool
    let autoOutputPresetEnabled: Bool
    let perDeviceSoundProfileEnabled: Bool
    let appearanceModeRawValue: String
}

enum RuntimeSettingsSummaryMapper {
    static func map(_ source: RuntimeSettingsSummarySource) -> RuntimeSettingsSummaryInput {
        RuntimeSettingsSummaryInput(
            selectedProfileRawValue: source.selectedProfileRawValue,
            sound: SoundSettings(
                volume: source.volume,
                variation: source.variation,
                pitchVariation: source.pitchVariation,
                pressLevel: source.pressLevel,
                releaseLevel: source.releaseLevel,
                spaceLevel: source.spaceLevel,
                stackModeEnabled: source.stackModeEnabled,
                limiterEnabled: source.limiterEnabled,
                limiterDrive: source.limiterDrive,
                minInterKeyGapMs: source.minInterKeyGapMs,
                releaseDuckingStrength: source.releaseDuckingStrength,
                releaseDuckingWindowMs: source.releaseDuckingWindowMs,
                releaseTailTightness: source.releaseTailTightness
            ),
            compensation: CompensationSettings(
                levelMacLow: source.levelMacLow,
                levelKbdLow: source.levelKbdLow,
                levelMacLowMid: source.levelMacLowMid,
                levelKbdLowMid: source.levelKbdLowMid,
                levelMacMid: source.levelMacMid,
                levelKbdMid: source.levelKbdMid,
                levelMacHighMid: source.levelMacHighMid,
                levelKbdHighMid: source.levelKbdHighMid,
                levelMacHigh: source.levelMacHigh,
                levelKbdHigh: source.levelKbdHigh,
                dynamicCompensationEnabled: source.dynamicCompensationEnabled,
                strictVolumeNormalizationEnabled: source.strictVolumeNormalizationEnabled
            ),
            typingAdaptiveEnabled: source.typingAdaptiveEnabled,
            system: SystemSettings(
                launchAtLogin: source.launchAtLogin,
                autoOutputPresetEnabled: source.autoOutputPresetEnabled,
                perDeviceSoundProfileEnabled: source.perDeviceSoundProfileEnabled,
                appearanceModeRawValue: source.appearanceModeRawValue
            )
        )
    }
}
