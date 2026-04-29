import Foundation

struct SoundSettings {
    var volume: Double
    var variation: Double
    var pitchVariation: Double
    var pressLevel: Double
    var releaseLevel: Double
    var spaceLevel: Double
    var stackModeEnabled: Bool
    var limiterEnabled: Bool
    var limiterDrive: Double
    var minInterKeyGapMs: Double
    var releaseDuckingStrength: Double
    var releaseDuckingWindowMs: Double
    var releaseTailTightness: Double
}

struct CompensationSettings {
    var levelMacLow: Double
    var levelKbdLow: Double
    var levelMacLowMid: Double
    var levelKbdLowMid: Double
    var levelMacMid: Double
    var levelKbdMid: Double
    var levelMacHighMid: Double
    var levelKbdHighMid: Double
    var levelMacHigh: Double
    var levelKbdHigh: Double
    var dynamicCompensationEnabled: Bool
    var strictVolumeNormalizationEnabled: Bool
}

struct SystemSettings {
    var launchAtLogin: Bool
    var autoOutputPresetEnabled: Bool
    var perDeviceSoundProfileEnabled: Bool
    var appearanceModeRawValue: String
}

struct DeviceSoundSnapshot: Codable {
    var volume: Double
    var variation: Double
    var pitchVariation: Double
    var pressLevel: Double
    var releaseLevel: Double
    var spaceLevel: Double
    var levelMacLowMid: Double
    var levelKbdLowMid: Double
    var levelMacHighMid: Double
    var levelKbdHighMid: Double
    var stackModeEnabled: Bool
    var limiterEnabled: Bool
    var limiterDrive: Double
    var minInterKeyGapMs: Double
    var releaseDuckingStrength: Double
    var releaseDuckingWindowMs: Double
    var releaseTailTightness: Double
    var currentOutputDeviceBoost: Double

    private enum CodingKeys: String, CodingKey {
        case volume
        case variation
        case pitchVariation
        case pressLevel
        case releaseLevel
        case spaceLevel
        case levelMacLowMid
        case levelKbdLowMid
        case levelMacHighMid
        case levelKbdHighMid
        case stackModeEnabled
        case limiterEnabled
        case limiterDrive
        case minInterKeyGapMs
        case releaseDuckingStrength
        case releaseDuckingWindowMs
        case releaseTailTightness
        case currentOutputDeviceBoost
    }

    init(
        volume: Double,
        variation: Double,
        pitchVariation: Double,
        pressLevel: Double,
        releaseLevel: Double,
        spaceLevel: Double,
        levelMacLowMid: Double,
        levelKbdLowMid: Double,
        levelMacHighMid: Double,
        levelKbdHighMid: Double,
        stackModeEnabled: Bool,
        limiterEnabled: Bool,
        limiterDrive: Double,
        minInterKeyGapMs: Double,
        releaseDuckingStrength: Double,
        releaseDuckingWindowMs: Double,
        releaseTailTightness: Double,
        currentOutputDeviceBoost: Double
    ) {
        self.volume = volume
        self.variation = variation
        self.pitchVariation = pitchVariation
        self.pressLevel = pressLevel
        self.releaseLevel = releaseLevel
        self.spaceLevel = spaceLevel
        self.levelMacLowMid = levelMacLowMid
        self.levelKbdLowMid = levelKbdLowMid
        self.levelMacHighMid = levelMacHighMid
        self.levelKbdHighMid = levelKbdHighMid
        self.stackModeEnabled = stackModeEnabled
        self.limiterEnabled = limiterEnabled
        self.limiterDrive = limiterDrive
        self.minInterKeyGapMs = minInterKeyGapMs
        self.releaseDuckingStrength = releaseDuckingStrength
        self.releaseDuckingWindowMs = releaseDuckingWindowMs
        self.releaseTailTightness = releaseTailTightness
        self.currentOutputDeviceBoost = currentOutputDeviceBoost
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        volume = try c.decode(Double.self, forKey: .volume)
        variation = try c.decode(Double.self, forKey: .variation)
        pitchVariation = try c.decode(Double.self, forKey: .pitchVariation)
        pressLevel = try c.decode(Double.self, forKey: .pressLevel)
        releaseLevel = try c.decode(Double.self, forKey: .releaseLevel)
        spaceLevel = try c.decode(Double.self, forKey: .spaceLevel)
        levelMacLowMid = try c.decodeIfPresent(Double.self, forKey: .levelMacLowMid) ?? 0.45
        levelKbdLowMid = try c.decodeIfPresent(Double.self, forKey: .levelKbdLowMid) ?? 1.30
        levelMacHighMid = try c.decodeIfPresent(Double.self, forKey: .levelMacHighMid) ?? 0.80
        levelKbdHighMid = try c.decodeIfPresent(Double.self, forKey: .levelKbdHighMid) ?? 0.70
        stackModeEnabled = try c.decode(Bool.self, forKey: .stackModeEnabled)
        limiterEnabled = try c.decode(Bool.self, forKey: .limiterEnabled)
        limiterDrive = try c.decode(Double.self, forKey: .limiterDrive)
        minInterKeyGapMs = try c.decode(Double.self, forKey: .minInterKeyGapMs)
        releaseDuckingStrength = try c.decode(Double.self, forKey: .releaseDuckingStrength)
        releaseDuckingWindowMs = try c.decode(Double.self, forKey: .releaseDuckingWindowMs)
        releaseTailTightness = try c.decode(Double.self, forKey: .releaseTailTightness)
        currentOutputDeviceBoost = try c.decode(Double.self, forKey: .currentOutputDeviceBoost)
    }
}

struct ProfileSoundSnapshot: Codable {
    var playKeyUp: Bool
    var volume: Double
    var variation: Double
    var pitchVariation: Double
    var pressLevel: Double
    var releaseLevel: Double
    var spaceLevel: Double
    var stackModeEnabled: Bool
    var stackDensity: Double
    var layerThresholdSlam: Double
    var layerThresholdHard: Double
    var layerThresholdMedium: Double
    var limiterEnabled: Bool
    var limiterDrive: Double
    var minInterKeyGapMs: Double
    var releaseDuckingStrength: Double
    var releaseDuckingWindowMs: Double
    var releaseTailTightness: Double

    private enum CodingKeys: String, CodingKey {
        case playKeyUp
        case volume
        case variation
        case pitchVariation
        case pressLevel
        case releaseLevel
        case spaceLevel
        case stackModeEnabled
        case stackDensity
        case layerThresholdSlam
        case layerThresholdHard
        case layerThresholdMedium
        case limiterEnabled
        case limiterDrive
        case minInterKeyGapMs
        case releaseDuckingStrength
        case releaseDuckingWindowMs
        case releaseTailTightness
    }

    init(
        playKeyUp: Bool,
        volume: Double,
        variation: Double,
        pitchVariation: Double,
        pressLevel: Double,
        releaseLevel: Double,
        spaceLevel: Double,
        stackModeEnabled: Bool,
        stackDensity: Double,
        layerThresholdSlam: Double,
        layerThresholdHard: Double,
        layerThresholdMedium: Double,
        limiterEnabled: Bool,
        limiterDrive: Double,
        minInterKeyGapMs: Double,
        releaseDuckingStrength: Double,
        releaseDuckingWindowMs: Double,
        releaseTailTightness: Double
    ) {
        self.playKeyUp = playKeyUp
        self.volume = volume
        self.variation = variation
        self.pitchVariation = pitchVariation
        self.pressLevel = pressLevel
        self.releaseLevel = releaseLevel
        self.spaceLevel = spaceLevel
        self.stackModeEnabled = stackModeEnabled
        self.stackDensity = stackDensity
        self.layerThresholdSlam = layerThresholdSlam
        self.layerThresholdHard = layerThresholdHard
        self.layerThresholdMedium = layerThresholdMedium
        self.limiterEnabled = limiterEnabled
        self.limiterDrive = limiterDrive
        self.minInterKeyGapMs = minInterKeyGapMs
        self.releaseDuckingStrength = releaseDuckingStrength
        self.releaseDuckingWindowMs = releaseDuckingWindowMs
        self.releaseTailTightness = releaseTailTightness
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        playKeyUp = try c.decodeIfPresent(Bool.self, forKey: .playKeyUp) ?? true
        volume = try c.decodeIfPresent(Double.self, forKey: .volume) ?? 0.75
        variation = try c.decodeIfPresent(Double.self, forKey: .variation) ?? 0.3
        pitchVariation = try c.decodeIfPresent(Double.self, forKey: .pitchVariation) ?? 0.22
        pressLevel = try c.decodeIfPresent(Double.self, forKey: .pressLevel) ?? 1.0
        releaseLevel = try c.decodeIfPresent(Double.self, forKey: .releaseLevel) ?? 0.65
        spaceLevel = try c.decodeIfPresent(Double.self, forKey: .spaceLevel) ?? 1.1
        stackModeEnabled = try c.decodeIfPresent(Bool.self, forKey: .stackModeEnabled) ?? false
        stackDensity = try c.decodeIfPresent(Double.self, forKey: .stackDensity) ?? 0.55
        layerThresholdSlam = try c.decodeIfPresent(Double.self, forKey: .layerThresholdSlam) ?? 0.045
        layerThresholdHard = try c.decodeIfPresent(Double.self, forKey: .layerThresholdHard) ?? 0.085
        layerThresholdMedium = try c.decodeIfPresent(Double.self, forKey: .layerThresholdMedium) ?? 0.145
        limiterEnabled = try c.decodeIfPresent(Bool.self, forKey: .limiterEnabled) ?? true
        limiterDrive = try c.decodeIfPresent(Double.self, forKey: .limiterDrive) ?? 1.2
        minInterKeyGapMs = try c.decodeIfPresent(Double.self, forKey: .minInterKeyGapMs) ?? 14
        releaseDuckingStrength = try c.decodeIfPresent(Double.self, forKey: .releaseDuckingStrength) ?? 0.72
        releaseDuckingWindowMs = try c.decodeIfPresent(Double.self, forKey: .releaseDuckingWindowMs) ?? 92
        releaseTailTightness = try c.decodeIfPresent(Double.self, forKey: .releaseTailTightness) ?? 0.38
    }
}
