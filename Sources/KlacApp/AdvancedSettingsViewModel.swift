import Combine
import SwiftUI

@dynamicMemberLookup
@MainActor
final class AdvancedSettingsViewModel: ObservableObject {
    let service: KeyboardSoundService
    private var changeSubscription: AnyCancellable?

    init(service: KeyboardSoundService) {
        self.service = service
        changeSubscription = service.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    subscript<T>(dynamicMember keyPath: KeyPath<KeyboardSoundService, T>) -> T {
        service[keyPath: keyPath]
    }

    func binding<T>(_ keyPath: ReferenceWritableKeyPath<KeyboardSoundService, T>) -> Binding<T> {
        Binding(
            get: { [weak service] in
                guard let service else { fatalError("KeyboardSoundService deallocated") }
                return service[keyPath: keyPath]
            },
            set: { [weak service] newValue in
                service?[keyPath: keyPath] = newValue
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
