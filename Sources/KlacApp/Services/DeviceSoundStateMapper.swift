import Foundation

struct DeviceSoundStateSource {
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
}

enum DeviceSoundStateMapper {
    static func toDTO(_ source: DeviceSoundStateSource) -> DeviceSoundStateDTO {
        DeviceSoundStateDTO(
            volume: source.volume,
            variation: source.variation,
            pitchVariation: source.pitchVariation,
            pressLevel: source.pressLevel,
            releaseLevel: source.releaseLevel,
            spaceLevel: source.spaceLevel,
            levelMacLowMid: source.levelMacLowMid,
            levelKbdLowMid: source.levelKbdLowMid,
            levelMacHighMid: source.levelMacHighMid,
            levelKbdHighMid: source.levelKbdHighMid,
            stackModeEnabled: source.stackModeEnabled,
            limiterEnabled: source.limiterEnabled,
            limiterDrive: source.limiterDrive,
            minInterKeyGapMs: source.minInterKeyGapMs,
            releaseDuckingStrength: source.releaseDuckingStrength,
            releaseDuckingWindowMs: source.releaseDuckingWindowMs,
            releaseTailTightness: source.releaseTailTightness,
            currentOutputDeviceBoost: source.currentOutputDeviceBoost
        )
    }
}
