import Combine
import SwiftUI

@MainActor
final class AdvancedSettingsViewModel: ObservableObject {
    private let service: AdvancedSettingsServiceProtocol
    private var changeSubscription: AnyCancellable?

    init(service: AdvancedSettingsServiceProtocol) {
        self.service = service
        changeSubscription = service.changePublisher.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    var profilePresetLastApplied: String { service.profilePresetLastApplied }
    var liveDynamicGain: Double { service.liveDynamicGain }
    var liveTypingGain: Double { service.liveTypingGain }
    var typingCPS: Double { service.typingCPS }
    var typingWPM: Double { service.typingWPM }
    var liveVelocityLayer: String { service.liveVelocityLayer }
    var manifestValidationSummary: String { service.manifestValidationSummary }
    var manifestValidationIssues: [String] { service.manifestValidationIssues }
    var detectedSystemVolumeAvailable: Bool { service.detectedSystemVolumeAvailable }
    var detectedSystemVolumePercent: Double { service.detectedSystemVolumePercent }
    var currentOutputDeviceName: String { service.currentOutputDeviceName }
    var autoOutputPresetLastApplied: String { service.autoOutputPresetLastApplied }
    var stressTestInProgress: Bool { service.stressTestInProgress }
    var stressTestProgress: Double { service.stressTestProgress }
    var stressTestStatus: String { service.stressTestStatus }
    var debugLogPreview: String { service.debugLogPreview }
    var isABPlaying: Bool { service.isABPlaying }
    var dynamicCompensationEnabled: Bool { service.boolValue(.dynamicCompensationEnabled) }
    var stackModeEnabled: Bool { service.boolValue(.stackModeEnabled) }
    var limiterEnabled: Bool { service.boolValue(.limiterEnabled) }
    var strictVolumeNormalizationEnabled: Bool { service.boolValue(.strictVolumeNormalizationEnabled) }
    var levelTuningMode: KlacLevelTuningMode { service.enumValue(.levelTuningMode) }
    var appearanceMode: KlacAppearanceMode { service.enumValue(.appearanceMode) }
    var levelMacLow: Double { service.doubleValue(.levelMacLow) }
    var levelKbdLow: Double { service.doubleValue(.levelKbdLow) }
    var levelMacLowMid: Double { service.doubleValue(.levelMacLowMid) }
    var levelKbdLowMid: Double { service.doubleValue(.levelKbdLowMid) }
    var levelMacMid: Double { service.doubleValue(.levelMacMid) }
    var levelKbdMid: Double { service.doubleValue(.levelKbdMid) }
    var levelMacHighMid: Double { service.doubleValue(.levelMacHighMid) }
    var levelKbdHighMid: Double { service.doubleValue(.levelKbdHighMid) }
    var levelMacHigh: Double { service.doubleValue(.levelMacHigh) }
    var levelKbdHigh: Double { service.doubleValue(.levelKbdHigh) }

    func binding(_ key: AdvancedBoolSetting) -> Binding<Bool> {
        Binding(
            get: { [weak service] in
                service?.boolValue(key) ?? false
            },
            set: { [weak service] newValue in
                service?.setBool(newValue, for: key)
            }
        )
    }

    func binding(_ key: AdvancedDoubleSetting) -> Binding<Double> {
        Binding(
            get: { [weak service] in
                service?.doubleValue(key) ?? 0
            },
            set: { [weak service] newValue in
                service?.setDouble(newValue, for: key)
            }
        )
    }

    func binding<T: RawRepresentable>(_ setting: AdvancedEnumSetting<T>) -> Binding<T> {
        Binding(
            get: { [weak service] in
                guard let service else { fatalError("AdvancedSettingsServiceProtocol deallocated") }
                return service.enumValue(setting)
            },
            set: { [weak service] newValue in
                service?.setEnum(newValue, for: setting)
            }
        )
    }

    func playABComparison() {
        service.playABComparison()
    }

    func applyHeadphonesPreset() {
        service.applyHeadphonesPreset()
    }

    func applySpeakersPreset() {
        service.applySpeakersPreset()
    }

    func autoInverseGainPreview(systemVolumePercent: Double) -> Double {
        service.autoInverseGainPreview(systemVolumePercent: systemVolumePercent)
    }

    func refreshAccessibilityStatus(promptIfNeeded: Bool) {
        service.refreshAccessibilityStatus(promptIfNeeded: promptIfNeeded)
    }

    func runAccessRecoveryWizard() {
        service.runAccessRecoveryWizard()
    }

    func exportSettings() {
        service.exportSettings()
    }

    func importSettings() {
        service.importSettings()
    }

    func startStressTest(duration: TimeInterval) {
        service.startStressTest(duration: duration)
    }

    func exportDebugLog() {
        service.exportDebugLog()
    }

    func clearDebugLog() {
        service.clearDebugLog()
    }
}
