import Foundation

struct PersistedSoundStatePlan {
    let selectedProfile: SoundProfile
    let playKeyUp: Bool
    let autoProfileTuningEnabled: Bool
    let soundSettings: SoundSettings
    let stackDensity: Double
    let layerThresholdSlam: Double
    let layerThresholdHard: Double
    let layerThresholdMedium: Double
}

struct PersistedCompensationStatePlan {
    let dynamicCompensationEnabled: Bool
    let compensationStrength: Double
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
    let strictVolumeNormalizationEnabled: Bool
    let levelTuningMode: KlacLevelTuningMode
    let autoNormalizeTargetAt100: Double
    let typingAdaptiveEnabled: Bool
}

struct PersistedSystemStatePlan {
    let launchAtLogin: Bool
    let autoOutputPresetEnabled: Bool
    let perDeviceSoundProfileEnabled: Bool
    let appearanceMode: KlacAppearanceMode
}

struct PersistedStatePlan {
    let isEnabled: Bool
    let sound: PersistedSoundStatePlan
    let compensation: PersistedCompensationStatePlan
    let system: PersistedSystemStatePlan
}

enum PersistedStateCoordinator {
    static func makePlan(from state: SettingsRepository.State) -> PersistedStatePlan {
        PersistedStatePlan(
            isEnabled: state.isEnabled,
            sound: PersistedSoundStatePlan(
                selectedProfile: state.selectedProfile,
                playKeyUp: state.playKeyUp,
                autoProfileTuningEnabled: state.autoProfileTuningEnabled,
                soundSettings: SoundSettings(
                    volume: state.volume,
                    variation: state.variation,
                    pitchVariation: state.pitchVariation,
                    pressLevel: state.pressLevel,
                    releaseLevel: state.releaseLevel,
                    spaceLevel: state.spaceLevel,
                    stackModeEnabled: state.stackModeEnabled,
                    limiterEnabled: state.limiterEnabled,
                    limiterDrive: state.limiterDrive,
                    minInterKeyGapMs: state.minInterKeyGapMs,
                    releaseDuckingStrength: state.releaseDuckingStrength,
                    releaseDuckingWindowMs: state.releaseDuckingWindowMs,
                    releaseTailTightness: state.releaseTailTightness
                ),
                stackDensity: state.stackDensity,
                layerThresholdSlam: state.layerThresholdSlam,
                layerThresholdHard: state.layerThresholdHard,
                layerThresholdMedium: state.layerThresholdMedium
            ),
            compensation: PersistedCompensationStatePlan(
                dynamicCompensationEnabled: state.dynamicCompensationEnabled,
                compensationStrength: state.compensationStrength,
                levelMacLow: state.levelMacLow,
                levelKbdLow: state.levelKbdLow,
                levelMacLowMid: state.levelMacLowMid,
                levelKbdLowMid: state.levelKbdLowMid,
                levelMacMid: state.levelMacMid,
                levelKbdMid: state.levelKbdMid,
                levelMacHighMid: state.levelMacHighMid,
                levelKbdHighMid: state.levelKbdHighMid,
                levelMacHigh: state.levelMacHigh,
                levelKbdHigh: state.levelKbdHigh,
                strictVolumeNormalizationEnabled: state.strictVolumeNormalizationEnabled,
                levelTuningMode: state.levelTuningMode,
                autoNormalizeTargetAt100: state.autoNormalizeTargetAt100,
                typingAdaptiveEnabled: state.typingAdaptiveEnabled
            ),
            system: PersistedSystemStatePlan(
                launchAtLogin: state.launchAtLogin,
                autoOutputPresetEnabled: state.autoOutputPresetEnabled,
                perDeviceSoundProfileEnabled: state.perDeviceSoundProfileEnabled,
                appearanceMode: state.appearanceMode
            )
        )
    }
}
