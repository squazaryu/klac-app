import Combine
import Foundation

enum AdvancedBoolSetting {
    case autoProfileTuningEnabled
    case playKeyUp
    case dynamicCompensationEnabled
    case typingAdaptiveEnabled
    case stackModeEnabled
    case limiterEnabled
    case strictVolumeNormalizationEnabled
    case perDeviceSoundProfileEnabled
    case autoOutputPresetEnabled
    case launchAtLogin
}

enum AdvancedDoubleSetting {
    case volume
    case variation
    case pitchVariation
    case pressLevel
    case releaseLevel
    case spaceLevel
    case compensationStrength
    case stackDensity
    case layerThresholdSlam
    case layerThresholdHard
    case layerThresholdMedium
    case minInterKeyGapMs
    case releaseDuckingStrength
    case releaseDuckingWindowMs
    case releaseTailTightness
    case autoNormalizeTargetAt100
    case levelMacLow
    case levelKbdLow
    case levelMacLowMid
    case levelKbdLowMid
    case levelMacMid
    case levelKbdMid
    case levelMacHighMid
    case levelKbdHighMid
    case levelMacHigh
    case levelKbdHigh
    case limiterDrive
    case currentOutputDeviceBoost
}

enum AdvancedEnumKey {
    case abFeature
    case levelTuningMode
    case outputPresetMode
    case appearanceMode
}

struct AdvancedEnumSetting<T: RawRepresentable & CaseIterable> {
    let key: AdvancedEnumKey
}

extension AdvancedEnumSetting where T == KlacABFeature {
    static let abFeature = Self(key: .abFeature)
}

extension AdvancedEnumSetting where T == KlacLevelTuningMode {
    static let levelTuningMode = Self(key: .levelTuningMode)
}

extension AdvancedEnumSetting where T == KlacOutputPresetMode {
    static let outputPresetMode = Self(key: .outputPresetMode)
}

extension AdvancedEnumSetting where T == KlacAppearanceMode {
    static let appearanceMode = Self(key: .appearanceMode)
}

@MainActor
protocol AdvancedSettingsServiceProtocol: AnyObject {
    var changePublisher: AnyPublisher<Void, Never> { get }

    func boolValue(_ key: AdvancedBoolSetting) -> Bool
    func setBool(_ value: Bool, for key: AdvancedBoolSetting)

    func doubleValue(_ key: AdvancedDoubleSetting) -> Double
    func setDouble(_ value: Double, for key: AdvancedDoubleSetting)

    func enumValue<T: RawRepresentable & CaseIterable>(_ setting: AdvancedEnumSetting<T>) -> T
    func setEnum<T: RawRepresentable & CaseIterable>(_ value: T, for setting: AdvancedEnumSetting<T>)

    var profilePresetLastApplied: String { get }
    var liveDynamicGain: Double { get }
    var liveTypingGain: Double { get }
    var typingCPS: Double { get }
    var typingWPM: Double { get }
    var liveVelocityLayer: String { get }
    var manifestValidationSummary: String { get }
    var manifestValidationIssues: [String] { get }
    var detectedSystemVolumeAvailable: Bool { get }
    var detectedSystemVolumePercent: Double { get }
    var currentOutputDeviceName: String { get }
    var autoOutputPresetLastApplied: String { get }
    var stressTestInProgress: Bool { get }
    var stressTestProgress: Double { get }
    var stressTestStatus: String { get }
    var debugLogPreview: String { get }
    var isABPlaying: Bool { get }

    func playABComparison()
    func applyHeadphonesPreset()
    func applySpeakersPreset()
    func autoInverseGainPreview(systemVolumePercent: Double) -> Double
    func refreshAccessibilityStatus(promptIfNeeded: Bool)
    func runAccessRecoveryWizard()
    func exportSettings()
    func importSettings()
    func startStressTest(duration: TimeInterval)
    func exportDebugLog()
    func clearDebugLog()
}
