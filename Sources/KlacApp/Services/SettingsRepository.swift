import Foundation

struct SettingsRepository {
    struct State {
        var isEnabled = true
        var volume = 0.75
        var variation = 0.3
        var pitchVariation = 0.22
        var playKeyUp = true
        var pressLevel = 1.0
        var releaseLevel = 0.65
        var spaceLevel = 1.1
        var autoProfileTuningEnabled = true
        var selectedProfile: SoundProfile = .kalihBoxWhite
        var launchAtLogin = false
        var dynamicCompensationEnabled = false
        var compensationStrength = 1.0
        var levelMacLow = 0.30
        var levelKbdLow = 1.60
        var levelMacLowMid = 0.45
        var levelKbdLowMid = 1.30
        var levelMacMid = 0.60
        var levelKbdMid = 1.00
        var levelMacHighMid = 0.80
        var levelKbdHighMid = 0.70
        var levelMacHigh = 1.00
        var levelKbdHigh = 0.45
        var strictVolumeNormalizationEnabled = true
        var levelTuningMode: KlacLevelTuningMode = .curve
        var autoNormalizeTargetAt100 = 0.45
        var typingAdaptiveEnabled = false
        var stackModeEnabled = false
        var stackDensity = 0.55
        var layerThresholdSlam = 0.045
        var layerThresholdHard = 0.085
        var layerThresholdMedium = 0.145
        var minInterKeyGapMs = 14.0
        var releaseDuckingStrength = 0.72
        var releaseDuckingWindowMs = 92.0
        var releaseTailTightness = 0.38
        var limiterEnabled = true
        var limiterDrive = 1.2
        var outputDeviceBoosts: [String: Double] = [:]
        var perDeviceSoundSnapshots: [String: DeviceSoundSnapshot] = [:]
        var autoOutputPresetEnabled = true
        var perDeviceSoundProfileEnabled = true
        var appearanceMode: KlacAppearanceMode = .system
        var hasPrimaryPersistedSettings = false
    }

    private let store: SettingsStore
    private let migrationFlagKey = "settings.migratedLegacyDefaults.v1"

    init(store: SettingsStore = SettingsStore()) {
        self.store = store
    }

    func loadState() -> State {
        migrateLegacySettingsIfNeeded()

        var state = State()
        state.hasPrimaryPersistedSettings = hasPrimaryPersistedSettings()

        if store.object(forKey: SettingsKeys.isEnabled) != nil {
            state.isEnabled = store.bool(forKey: SettingsKeys.isEnabled)
        }
        if store.object(forKey: SettingsKeys.volume) != nil {
            state.volume = store.double(forKey: SettingsKeys.volume)
        }
        if store.object(forKey: SettingsKeys.variation) != nil {
            state.variation = store.double(forKey: SettingsKeys.variation)
        }
        if store.object(forKey: SettingsKeys.pitchVariation) != nil {
            state.pitchVariation = store.double(forKey: SettingsKeys.pitchVariation).clamped(to: 0.0 ... 0.6)
        }
        if store.object(forKey: SettingsKeys.playKeyUp) != nil {
            state.playKeyUp = store.bool(forKey: SettingsKeys.playKeyUp)
        }
        if store.object(forKey: SettingsKeys.pressLevel) != nil {
            state.pressLevel = store.double(forKey: SettingsKeys.pressLevel)
        }
        if store.object(forKey: SettingsKeys.releaseLevel) != nil {
            state.releaseLevel = store.double(forKey: SettingsKeys.releaseLevel)
        }
        if store.object(forKey: SettingsKeys.spaceLevel) != nil {
            state.spaceLevel = store.double(forKey: SettingsKeys.spaceLevel)
        }
        if store.object(forKey: SettingsKeys.autoProfileTuningEnabled) != nil {
            state.autoProfileTuningEnabled = store.bool(forKey: SettingsKeys.autoProfileTuningEnabled)
        }
        if let profileRaw = store.string(forKey: SettingsKeys.selectedProfile),
           let profile = SoundProfile(rawValue: profileRaw) {
            state.selectedProfile = profile
        }
        if store.object(forKey: SettingsKeys.launchAtLogin) != nil {
            state.launchAtLogin = store.bool(forKey: SettingsKeys.launchAtLogin)
        }
        if store.object(forKey: SettingsKeys.dynamicCompensationEnabled) != nil {
            state.dynamicCompensationEnabled = store.bool(forKey: SettingsKeys.dynamicCompensationEnabled)
        }
        if store.object(forKey: SettingsKeys.compensationStrength) != nil {
            state.compensationStrength = store.double(forKey: SettingsKeys.compensationStrength)
        }
        if store.object(forKey: SettingsKeys.levelMacLow) != nil {
            state.levelMacLow = store.double(forKey: SettingsKeys.levelMacLow).clamped(to: 0.05 ... 0.90)
        }
        if store.object(forKey: SettingsKeys.levelKbdLow) != nil {
            state.levelKbdLow = store.double(forKey: SettingsKeys.levelKbdLow).clamped(to: 0.20 ... 4.00)
        }
        if store.object(forKey: SettingsKeys.levelMacMid) != nil {
            state.levelMacMid = store.double(forKey: SettingsKeys.levelMacMid).clamped(to: 0.05 ... 0.95)
        }
        if store.object(forKey: SettingsKeys.levelKbdMid) != nil {
            state.levelKbdMid = store.double(forKey: SettingsKeys.levelKbdMid).clamped(to: 0.20 ... 4.00)
        }
        if store.object(forKey: SettingsKeys.levelMacHigh) != nil {
            state.levelMacHigh = store.double(forKey: SettingsKeys.levelMacHigh).clamped(to: 0.10 ... 1.00)
        }
        if store.object(forKey: SettingsKeys.levelKbdHigh) != nil {
            state.levelKbdHigh = store.double(forKey: SettingsKeys.levelKbdHigh).clamped(to: 0.20 ... 4.00)
        }

        if store.object(forKey: SettingsKeys.levelMacLowMid) != nil {
            state.levelMacLowMid = store.double(forKey: SettingsKeys.levelMacLowMid).clamped(to: 0.08 ... 0.93)
        } else {
            state.levelMacLowMid = ((state.levelMacLow + state.levelMacMid) * 0.5).clamped(to: 0.08 ... 0.93)
        }
        if store.object(forKey: SettingsKeys.levelKbdLowMid) != nil {
            state.levelKbdLowMid = store.double(forKey: SettingsKeys.levelKbdLowMid).clamped(to: 0.20 ... 4.00)
        } else {
            state.levelKbdLowMid = ((state.levelKbdLow + state.levelKbdMid) * 0.5).clamped(to: 0.20 ... 4.00)
        }
        if store.object(forKey: SettingsKeys.levelMacHighMid) != nil {
            state.levelMacHighMid = store.double(forKey: SettingsKeys.levelMacHighMid).clamped(to: 0.10 ... 0.98)
        } else {
            state.levelMacHighMid = ((state.levelMacMid + state.levelMacHigh) * 0.5).clamped(to: 0.10 ... 0.98)
        }
        if store.object(forKey: SettingsKeys.levelKbdHighMid) != nil {
            state.levelKbdHighMid = store.double(forKey: SettingsKeys.levelKbdHighMid).clamped(to: 0.20 ... 4.00)
        } else {
            state.levelKbdHighMid = ((state.levelKbdMid + state.levelKbdHigh) * 0.5).clamped(to: 0.20 ... 4.00)
        }

        if store.object(forKey: SettingsKeys.strictVolumeNormalizationEnabled) != nil {
            state.strictVolumeNormalizationEnabled = store.bool(forKey: SettingsKeys.strictVolumeNormalizationEnabled)
        }
        if let modeRaw = store.string(forKey: SettingsKeys.levelTuningMode),
           let mode = KlacLevelTuningMode(rawValue: modeRaw) {
            state.levelTuningMode = mode
        }
        if store.object(forKey: SettingsKeys.autoNormalizeTargetAt100) != nil {
            state.autoNormalizeTargetAt100 = store.double(forKey: SettingsKeys.autoNormalizeTargetAt100).clamped(to: 0.20 ... 1.20)
        }
        if store.object(forKey: SettingsKeys.typingAdaptiveEnabled) != nil {
            state.typingAdaptiveEnabled = store.bool(forKey: SettingsKeys.typingAdaptiveEnabled)
        }
        if store.object(forKey: SettingsKeys.stackModeEnabled) != nil {
            state.stackModeEnabled = store.bool(forKey: SettingsKeys.stackModeEnabled)
        }
        if store.object(forKey: SettingsKeys.stackDensity) != nil {
            state.stackDensity = store.double(forKey: SettingsKeys.stackDensity)
        }
        if store.object(forKey: SettingsKeys.layerThresholdSlam) != nil {
            state.layerThresholdSlam = store.double(forKey: SettingsKeys.layerThresholdSlam).clamped(to: 0.010 ... 0.120)
        }
        if store.object(forKey: SettingsKeys.layerThresholdHard) != nil {
            state.layerThresholdHard = store.double(forKey: SettingsKeys.layerThresholdHard).clamped(to: 0.025 ... 0.180)
        }
        if store.object(forKey: SettingsKeys.layerThresholdMedium) != nil {
            state.layerThresholdMedium = store.double(forKey: SettingsKeys.layerThresholdMedium).clamped(to: 0.040 ... 0.260)
        }
        if store.object(forKey: SettingsKeys.minInterKeyGapMs) != nil {
            state.minInterKeyGapMs = store.double(forKey: SettingsKeys.minInterKeyGapMs).clamped(to: 0 ... 45)
        }
        if store.object(forKey: SettingsKeys.releaseDuckingStrength) != nil {
            state.releaseDuckingStrength = store.double(forKey: SettingsKeys.releaseDuckingStrength).clamped(to: 0 ... 1)
        }
        if store.object(forKey: SettingsKeys.releaseDuckingWindowMs) != nil {
            state.releaseDuckingWindowMs = store.double(forKey: SettingsKeys.releaseDuckingWindowMs).clamped(to: 20 ... 180)
        }
        if store.object(forKey: SettingsKeys.releaseTailTightness) != nil {
            state.releaseTailTightness = store.double(forKey: SettingsKeys.releaseTailTightness).clamped(to: 0 ... 1)
        }
        if store.object(forKey: SettingsKeys.limiterEnabled) != nil {
            state.limiterEnabled = store.bool(forKey: SettingsKeys.limiterEnabled)
        }
        if store.object(forKey: SettingsKeys.limiterDrive) != nil {
            state.limiterDrive = store.double(forKey: SettingsKeys.limiterDrive)
        }
        if let decoded = store.decode([String: Double].self, forKey: SettingsKeys.outputDeviceBoosts) {
            state.outputDeviceBoosts = decoded
        }
        if let decoded = store.decode([String: DeviceSoundSnapshot].self, forKey: SettingsKeys.perDeviceSoundSnapshots) {
            state.perDeviceSoundSnapshots = decoded
        }
        if store.object(forKey: SettingsKeys.autoOutputPresetEnabled) != nil {
            state.autoOutputPresetEnabled = store.bool(forKey: SettingsKeys.autoOutputPresetEnabled)
        }
        if store.object(forKey: SettingsKeys.perDeviceSoundProfileEnabled) != nil {
            state.perDeviceSoundProfileEnabled = store.bool(forKey: SettingsKeys.perDeviceSoundProfileEnabled)
        }
        if let modeRaw = store.string(forKey: SettingsKeys.appearanceMode),
           let mode = KlacAppearanceMode(rawValue: modeRaw) {
            state.appearanceMode = mode
        }

        return state
    }

    private func hasPrimaryPersistedSettings() -> Bool {
        store.object(forKey: SettingsKeys.volume) != nil ||
            store.object(forKey: SettingsKeys.selectedProfile) != nil ||
            store.object(forKey: SettingsKeys.pressLevel) != nil
    }

    private func migrateLegacySettingsIfNeeded() {
        if store.bool(forKey: migrationFlagKey) { return }
        defer { store.set(true, forKey: migrationFlagKey) }

        guard !hasPrimaryPersistedSettings() else { return }
        guard let currentDomain = AppMetadataService.resolveBundleIdentifier(), !currentDomain.isEmpty else { return }

        for legacyDomain in ["com.tumowuh.klac"] where legacyDomain != currentDomain {
            guard let legacyValues = store.persistentDomain(forName: legacyDomain), !legacyValues.isEmpty else { continue }
            let migrated = legacyValues.filter { $0.key.hasPrefix("settings.") }
            guard !migrated.isEmpty else { continue }
            for (key, value) in migrated {
                store.set(value, forKey: key)
            }
            NSLog("Migrated \(migrated.count) settings from legacy domain \(legacyDomain)")
            break
        }
    }
}
