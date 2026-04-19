import Foundation

struct DeviceSoundStateDTO {
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

struct PerDeviceSnapshotService {
    private let settingsStore: SettingsStore
    private(set) var snapshots: [String: DeviceSoundSnapshot]
    private(set) var boosts: [String: Double]

    init(
        settingsStore: SettingsStore,
        snapshots: [String: DeviceSoundSnapshot],
        boosts: [String: Double]
    ) {
        self.settingsStore = settingsStore
        self.snapshots = snapshots
        self.boosts = boosts
    }

    func boost(for deviceUID: String) -> Double {
        guard !deviceUID.isEmpty else { return 1.0 }
        return boosts[deviceUID]?.clamped(to: 0.5 ... 2.0) ?? 1.0
    }

    mutating func setBoost(_ value: Double, for deviceUID: String) {
        guard !deviceUID.isEmpty else { return }
        boosts[deviceUID] = value.clamped(to: 0.5 ... 2.0)
        settingsStore.encode(boosts, forKey: SettingsKeys.outputDeviceBoosts)
    }

    mutating func saveSnapshot(deviceUID: String, state: DeviceSoundStateDTO) {
        guard !deviceUID.isEmpty else { return }
        snapshots[deviceUID] = DeviceSoundSnapshot(
            volume: state.volume.clamped(to: 0.0 ... 1.0),
            variation: state.variation.clamped(to: 0.0 ... 1.0),
            pitchVariation: state.pitchVariation.clamped(to: 0.0 ... 0.6),
            pressLevel: state.pressLevel.clamped(to: 0.2 ... 1.6),
            releaseLevel: state.releaseLevel.clamped(to: 0.1 ... 1.4),
            spaceLevel: state.spaceLevel.clamped(to: 0.2 ... 1.8),
            levelMacLowMid: state.levelMacLowMid.clamped(to: 0.08 ... 0.93),
            levelKbdLowMid: state.levelKbdLowMid.clamped(to: 0.20 ... 4.00),
            levelMacHighMid: state.levelMacHighMid.clamped(to: 0.10 ... 0.98),
            levelKbdHighMid: state.levelKbdHighMid.clamped(to: 0.20 ... 4.00),
            stackModeEnabled: state.stackModeEnabled,
            limiterEnabled: state.limiterEnabled,
            limiterDrive: state.limiterDrive.clamped(to: 0.6 ... 2.0),
            minInterKeyGapMs: state.minInterKeyGapMs.clamped(to: 0 ... 45),
            releaseDuckingStrength: state.releaseDuckingStrength.clamped(to: 0 ... 1),
            releaseDuckingWindowMs: state.releaseDuckingWindowMs.clamped(to: 20 ... 180),
            releaseTailTightness: state.releaseTailTightness.clamped(to: 0 ... 1),
            currentOutputDeviceBoost: state.currentOutputDeviceBoost.clamped(to: 0.5 ... 2.0)
        )
        settingsStore.encode(snapshots, forKey: SettingsKeys.perDeviceSoundSnapshots)
    }

    func snapshotExists(for deviceUID: String) -> Bool {
        snapshots[deviceUID] != nil
    }

    mutating func restoreSnapshot(deviceUID: String, apply: (DeviceSoundStateDTO) -> Void) -> Bool {
        guard let snapshot = snapshots[deviceUID] else { return false }
        let dto = DeviceSoundStateDTO(
            volume: snapshot.volume.clamped(to: 0.0 ... 1.0),
            variation: snapshot.variation.clamped(to: 0.0 ... 1.0),
            pitchVariation: snapshot.pitchVariation.clamped(to: 0.0 ... 0.6),
            pressLevel: snapshot.pressLevel.clamped(to: 0.2 ... 1.6),
            releaseLevel: snapshot.releaseLevel.clamped(to: 0.1 ... 1.4),
            spaceLevel: snapshot.spaceLevel.clamped(to: 0.2 ... 1.8),
            levelMacLowMid: snapshot.levelMacLowMid.clamped(to: 0.08 ... 0.93),
            levelKbdLowMid: snapshot.levelKbdLowMid.clamped(to: 0.20 ... 4.00),
            levelMacHighMid: snapshot.levelMacHighMid.clamped(to: 0.10 ... 0.98),
            levelKbdHighMid: snapshot.levelKbdHighMid.clamped(to: 0.20 ... 4.00),
            stackModeEnabled: snapshot.stackModeEnabled,
            limiterEnabled: snapshot.limiterEnabled,
            limiterDrive: snapshot.limiterDrive.clamped(to: 0.6 ... 2.0),
            minInterKeyGapMs: snapshot.minInterKeyGapMs.clamped(to: 0 ... 45),
            releaseDuckingStrength: snapshot.releaseDuckingStrength.clamped(to: 0 ... 1),
            releaseDuckingWindowMs: snapshot.releaseDuckingWindowMs.clamped(to: 20 ... 180),
            releaseTailTightness: snapshot.releaseTailTightness.clamped(to: 0 ... 1),
            currentOutputDeviceBoost: snapshot.currentOutputDeviceBoost.clamped(to: 0.5 ... 2.0)
        )
        apply(dto)
        return true
    }
}
