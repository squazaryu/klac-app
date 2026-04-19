import Foundation

struct SoundStatePatch {
    var selectedProfile: SoundProfile?
    var volume: Double?
    var variation: Double?
    var playKeyUp: Bool?
    var pitchVariation: Double?
    var pressLevel: Double?
    var releaseLevel: Double?
    var spaceLevel: Double?
    var levelMacLowMid: Double?
    var levelKbdLowMid: Double?
    var levelMacHighMid: Double?
    var levelKbdHighMid: Double?
    var stackModeEnabled: Bool?
    var limiterEnabled: Bool?
    var limiterDrive: Double?
    var minInterKeyGapMs: Double?
    var releaseDuckingStrength: Double?
    var releaseDuckingWindowMs: Double?
    var releaseTailTightness: Double?
    var currentOutputDeviceBoost: Double?
}

enum SoundStatePatchMapper {
    static func importedProfilePatch(from state: ProfileSettingsState) -> SoundStatePatch {
        SoundStatePatch(
            selectedProfile: state.selectedProfile,
            volume: state.volume,
            variation: state.variation,
            playKeyUp: state.playKeyUp,
            pitchVariation: nil,
            pressLevel: state.pressLevel,
            releaseLevel: state.releaseLevel,
            spaceLevel: state.spaceLevel,
            levelMacLowMid: nil,
            levelKbdLowMid: nil,
            levelMacHighMid: nil,
            levelKbdHighMid: nil,
            stackModeEnabled: nil,
            limiterEnabled: nil,
            limiterDrive: nil,
            minInterKeyGapMs: nil,
            releaseDuckingStrength: nil,
            releaseDuckingWindowMs: nil,
            releaseTailTightness: nil,
            currentOutputDeviceBoost: nil
        )
    }

    static func deviceSnapshotPatch(from snapshot: DeviceSoundStateDTO) -> SoundStatePatch {
        SoundStatePatch(
            selectedProfile: nil,
            volume: snapshot.volume,
            variation: snapshot.variation,
            playKeyUp: nil,
            pitchVariation: snapshot.pitchVariation,
            pressLevel: snapshot.pressLevel,
            releaseLevel: snapshot.releaseLevel,
            spaceLevel: snapshot.spaceLevel,
            levelMacLowMid: snapshot.levelMacLowMid,
            levelKbdLowMid: snapshot.levelKbdLowMid,
            levelMacHighMid: snapshot.levelMacHighMid,
            levelKbdHighMid: snapshot.levelKbdHighMid,
            stackModeEnabled: snapshot.stackModeEnabled,
            limiterEnabled: snapshot.limiterEnabled,
            limiterDrive: snapshot.limiterDrive,
            minInterKeyGapMs: snapshot.minInterKeyGapMs,
            releaseDuckingStrength: snapshot.releaseDuckingStrength,
            releaseDuckingWindowMs: snapshot.releaseDuckingWindowMs,
            releaseTailTightness: snapshot.releaseTailTightness,
            currentOutputDeviceBoost: snapshot.currentOutputDeviceBoost
        )
    }
}
