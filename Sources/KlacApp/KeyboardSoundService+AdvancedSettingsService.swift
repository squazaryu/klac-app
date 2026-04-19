import Foundation

@MainActor
extension KeyboardSoundService: AdvancedSettingsServiceProtocol {
    func boolValue(_ key: AdvancedBoolSetting) -> Bool {
        switch key {
        case .autoProfileTuningEnabled: return autoProfileTuningEnabled
        case .playKeyUp: return playKeyUp
        case .dynamicCompensationEnabled: return dynamicCompensationEnabled
        case .typingAdaptiveEnabled: return typingAdaptiveEnabled
        case .stackModeEnabled: return stackModeEnabled
        case .limiterEnabled: return limiterEnabled
        case .strictVolumeNormalizationEnabled: return strictVolumeNormalizationEnabled
        case .perDeviceSoundProfileEnabled: return perDeviceSoundProfileEnabled
        case .autoOutputPresetEnabled: return autoOutputPresetEnabled
        case .launchAtLogin: return launchAtLogin
        }
    }

    func setBool(_ value: Bool, for key: AdvancedBoolSetting) {
        switch key {
        case .autoProfileTuningEnabled: autoProfileTuningEnabled = value
        case .playKeyUp: playKeyUp = value
        case .dynamicCompensationEnabled: dynamicCompensationEnabled = value
        case .typingAdaptiveEnabled: typingAdaptiveEnabled = value
        case .stackModeEnabled: stackModeEnabled = value
        case .limiterEnabled: limiterEnabled = value
        case .strictVolumeNormalizationEnabled: strictVolumeNormalizationEnabled = value
        case .perDeviceSoundProfileEnabled: perDeviceSoundProfileEnabled = value
        case .autoOutputPresetEnabled: autoOutputPresetEnabled = value
        case .launchAtLogin: launchAtLogin = value
        }
    }

    func doubleValue(_ key: AdvancedDoubleSetting) -> Double {
        switch key {
        case .volume: return volume
        case .variation: return variation
        case .pitchVariation: return pitchVariation
        case .pressLevel: return pressLevel
        case .releaseLevel: return releaseLevel
        case .spaceLevel: return spaceLevel
        case .compensationStrength: return compensationStrength
        case .stackDensity: return stackDensity
        case .layerThresholdSlam: return layerThresholdSlam
        case .layerThresholdHard: return layerThresholdHard
        case .layerThresholdMedium: return layerThresholdMedium
        case .minInterKeyGapMs: return minInterKeyGapMs
        case .releaseDuckingStrength: return releaseDuckingStrength
        case .releaseDuckingWindowMs: return releaseDuckingWindowMs
        case .releaseTailTightness: return releaseTailTightness
        case .autoNormalizeTargetAt100: return autoNormalizeTargetAt100
        case .levelMacLow: return levelMacLow
        case .levelKbdLow: return levelKbdLow
        case .levelMacLowMid: return levelMacLowMid
        case .levelKbdLowMid: return levelKbdLowMid
        case .levelMacMid: return levelMacMid
        case .levelKbdMid: return levelKbdMid
        case .levelMacHighMid: return levelMacHighMid
        case .levelKbdHighMid: return levelKbdHighMid
        case .levelMacHigh: return levelMacHigh
        case .levelKbdHigh: return levelKbdHigh
        case .limiterDrive: return limiterDrive
        case .currentOutputDeviceBoost: return currentOutputDeviceBoost
        }
    }

    func setDouble(_ value: Double, for key: AdvancedDoubleSetting) {
        switch key {
        case .volume: volume = value
        case .variation: variation = value
        case .pitchVariation: pitchVariation = value
        case .pressLevel: pressLevel = value
        case .releaseLevel: releaseLevel = value
        case .spaceLevel: spaceLevel = value
        case .compensationStrength: compensationStrength = value
        case .stackDensity: stackDensity = value
        case .layerThresholdSlam: layerThresholdSlam = value
        case .layerThresholdHard: layerThresholdHard = value
        case .layerThresholdMedium: layerThresholdMedium = value
        case .minInterKeyGapMs: minInterKeyGapMs = value
        case .releaseDuckingStrength: releaseDuckingStrength = value
        case .releaseDuckingWindowMs: releaseDuckingWindowMs = value
        case .releaseTailTightness: releaseTailTightness = value
        case .autoNormalizeTargetAt100: autoNormalizeTargetAt100 = value
        case .levelMacLow: levelMacLow = value
        case .levelKbdLow: levelKbdLow = value
        case .levelMacLowMid: levelMacLowMid = value
        case .levelKbdLowMid: levelKbdLowMid = value
        case .levelMacMid: levelMacMid = value
        case .levelKbdMid: levelKbdMid = value
        case .levelMacHighMid: levelMacHighMid = value
        case .levelKbdHighMid: levelKbdHighMid = value
        case .levelMacHigh: levelMacHigh = value
        case .levelKbdHigh: levelKbdHigh = value
        case .limiterDrive: limiterDrive = value
        case .currentOutputDeviceBoost: currentOutputDeviceBoost = value
        }
    }

    func enumValue<T>(_ setting: AdvancedEnumSetting<T>) -> T where T: RawRepresentable {
        switch setting.key {
        case .abFeature:
            return castEnum(abFeature, as: T.self, context: "abFeature")
        case .levelTuningMode:
            return castEnum(levelTuningMode, as: T.self, context: "levelTuningMode")
        case .outputPresetMode:
            return castEnum(currentOutputPresetMode, as: T.self, context: "outputPresetMode")
        case .appearanceMode:
            return castEnum(appearanceMode, as: T.self, context: "appearanceMode")
        }
    }

    func setEnum<T>(_ value: T, for setting: AdvancedEnumSetting<T>) where T: RawRepresentable {
        switch setting.key {
        case .abFeature:
            guard let typed = value as? KlacABFeature else { return }
            abFeature = typed
        case .levelTuningMode:
            guard let typed = value as? KlacLevelTuningMode else { return }
            levelTuningMode = typed
        case .outputPresetMode:
            guard let typed = value as? KlacOutputPresetMode else { return }
            currentOutputPresetMode = typed
        case .appearanceMode:
            guard let typed = value as? KlacAppearanceMode else { return }
            appearanceMode = typed
        }
    }

    private func castEnum<T: RawRepresentable>(_ value: some RawRepresentable, as type: T.Type, context: String) -> T {
        guard let typed = value as? T else {
            fatalError("Advanced enum type mismatch for \(context)")
        }
        return typed
    }
}
