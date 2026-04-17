import Foundation

struct ProfileSoundPreset {
    let settings: SoundSettings
    let label: String
}

enum SoundPresetService {
    static func headphonesPreset() -> SoundSettings {
        SoundSettings(
            volume: 0.62,
            variation: 0.42,
            pitchVariation: 0.28,
            pressLevel: 0.82,
            releaseLevel: 0.56,
            spaceLevel: 0.86,
            stackModeEnabled: false,
            limiterEnabled: true,
            limiterDrive: 1.1,
            minInterKeyGapMs: 18,
            releaseDuckingStrength: 0.86,
            releaseDuckingWindowMs: 105,
            releaseTailTightness: 0.62
        )
    }

    static func speakersPreset() -> SoundSettings {
        SoundSettings(
            volume: 0.46,
            variation: 0.34,
            pitchVariation: 0.20,
            pressLevel: 0.72,
            releaseLevel: 0.50,
            spaceLevel: 0.78,
            stackModeEnabled: false,
            limiterEnabled: true,
            limiterDrive: 1.0,
            minInterKeyGapMs: 10,
            releaseDuckingStrength: 0.64,
            releaseDuckingWindowMs: 88,
            releaseTailTightness: 0.40
        )
    }

    static func profilePreset(for profile: SoundProfile) -> ProfileSoundPreset? {
        switch profile {
        case .mechvibesCherryMXBlackABS:
            return ProfileSoundPreset(
                settings: SoundSettings(
                    volume: 0.62,
                    variation: 0.24,
                    pitchVariation: 0.12,
                    pressLevel: 0.78,
                    releaseLevel: 0.42,
                    spaceLevel: 0.82,
                    stackModeEnabled: false,
                    limiterEnabled: true,
                    limiterDrive: 1.1,
                    minInterKeyGapMs: 12,
                    releaseDuckingStrength: 0.68,
                    releaseDuckingWindowMs: 82,
                    releaseTailTightness: 0.45
                ),
                label: "ABS: плотный и сухой"
            )
        case .mechvibesCherryMXBlackPBT:
            return ProfileSoundPreset(
                settings: SoundSettings(
                    volume: 0.62,
                    variation: 0.30,
                    pitchVariation: 0.16,
                    pressLevel: 0.82,
                    releaseLevel: 0.46,
                    spaceLevel: 0.84,
                    stackModeEnabled: false,
                    limiterEnabled: true,
                    limiterDrive: 1.1,
                    minInterKeyGapMs: 13,
                    releaseDuckingStrength: 0.70,
                    releaseDuckingWindowMs: 86,
                    releaseTailTightness: 0.48
                ),
                label: "PBT: чуть ярче атака"
            )
        case .mechvibesEGCrystalPurple:
            return ProfileSoundPreset(
                settings: SoundSettings(
                    volume: 0.62,
                    variation: 0.38,
                    pitchVariation: 0.25,
                    pressLevel: 0.86,
                    releaseLevel: 0.52,
                    spaceLevel: 0.90,
                    stackModeEnabled: false,
                    limiterEnabled: true,
                    limiterDrive: 1.1,
                    minInterKeyGapMs: 15,
                    releaseDuckingStrength: 0.76,
                    releaseDuckingWindowMs: 98,
                    releaseTailTightness: 0.55
                ),
                label: "Crystal Purple: живой и звонкий"
            )
        case .mechvibesEGOreo:
            return ProfileSoundPreset(
                settings: SoundSettings(
                    volume: 0.62,
                    variation: 0.28,
                    pitchVariation: 0.18,
                    pressLevel: 0.80,
                    releaseLevel: 0.44,
                    spaceLevel: 0.85,
                    stackModeEnabled: false,
                    limiterEnabled: true,
                    limiterDrive: 1.1,
                    minInterKeyGapMs: 14,
                    releaseDuckingStrength: 0.72,
                    releaseDuckingWindowMs: 92,
                    releaseTailTightness: 0.50
                ),
                label: "Oreo: мягче и глубже"
            )
        default:
            return nil
        }
    }
}
