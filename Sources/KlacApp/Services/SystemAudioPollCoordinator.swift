import CoreAudio
import Foundation

struct SystemAudioPollState {
    var detectedSystemVolumeAvailable: Bool
    var detectedSystemVolumePercent: Double
    var lastSystemVolume: Double
    var lastOutputDeviceID: AudioObjectID
    var currentOutputDeviceUID: String
    var currentOutputDeviceName: String
    var initialOutputDeviceResolved: Bool
}

struct SystemAudioPollResult {
    let state: SystemAudioPollState
    let volumeChanged: Bool
    let availabilityChanged: Bool
    let deviceChanged: Bool
    let previousDeviceUID: String
    let deviceUID: String
    let deviceName: String
    let isInitialProbe: Bool
}

enum SystemAudioPollCoordinator {
    static func process(payload: SystemAudioPollPayload, state: SystemAudioPollState) -> SystemAudioPollResult {
        var nextState = state
        let wasVolumeAvailable = state.detectedSystemVolumeAvailable

        nextState.detectedSystemVolumeAvailable = payload.scalar != nil
        if let scalar = payload.scalar {
            nextState.detectedSystemVolumePercent = scalar * 100.0
        }

        let nextVolume = payload.scalar ?? state.lastSystemVolume
        let volumeChanged = abs(state.lastSystemVolume - nextVolume) > 0.005
        if volumeChanged {
            nextState.lastSystemVolume = nextVolume
        }

        let deviceChanged = payload.deviceID != state.lastOutputDeviceID || payload.deviceUID != state.currentOutputDeviceUID
        let previousDeviceUID = state.currentOutputDeviceUID
        let isInitialProbe = !state.initialOutputDeviceResolved && deviceChanged

        if deviceChanged {
            nextState.lastOutputDeviceID = payload.deviceID
            nextState.currentOutputDeviceUID = payload.deviceUID
            nextState.currentOutputDeviceName = payload.deviceName
            nextState.initialOutputDeviceResolved = true
        }

        let availabilityChanged = wasVolumeAvailable != nextState.detectedSystemVolumeAvailable

        return SystemAudioPollResult(
            state: nextState,
            volumeChanged: volumeChanged,
            availabilityChanged: availabilityChanged,
            deviceChanged: deviceChanged,
            previousDeviceUID: previousDeviceUID,
            deviceUID: payload.deviceUID,
            deviceName: payload.deviceName,
            isInitialProbe: isInitialProbe
        )
    }

    static func shouldApplyAutoPreset(
        isInitialProbe: Bool,
        hasPersistedPrimarySettings: Bool,
        restoredSnapshot: Bool
    ) -> Bool {
        guard !restoredSnapshot else { return false }
        return !isInitialProbe || !hasPersistedPrimarySettings
    }
}
