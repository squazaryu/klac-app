import Combine
import SwiftUI

@MainActor
final class MenuBarViewModel: ObservableObject {
    @Published private(set) var isEnabled: Bool = true
    @Published private(set) var capturingKeyboard: Bool = false
    @Published private(set) var accessibilityGranted: Bool = false
    @Published private(set) var inputMonitoringGranted: Bool = false
    @Published private(set) var accessActionHint: String?
    @Published private(set) var selectedProfile: SoundProfile = .kalihBoxWhite
    @Published private(set) var appearanceMode: KlacAppearanceMode = .system

    private let service: MenuBarServiceProtocol
    private var changeSubscription: AnyCancellable?

    init(service: MenuBarServiceProtocol) {
        self.service = service
        pullFromService()
        changeSubscription = service.changePublisher.sink { [weak self] _ in
            Task { @MainActor in
                self?.pullFromService()
            }
        }
    }

    func start() {
        service.start()
        pullFromService()
    }

    func setEnabled(_ enabled: Bool) {
        service.isEnabled = enabled
        enabled ? service.start() : service.stop()
        pullFromService()
    }

    func selectProfile(_ profile: SoundProfile) {
        service.selectedProfile = profile
        pullFromService()
    }

    func checkForUpdates() {
        service.checkForUpdatesInteractive()
    }

    func openAdvancedSettings() {
        pullFromService()
    }

    func makeAdvancedSettingsViewModel() -> AdvancedSettingsViewModel {
        service.makeAdvancedSettingsViewModel()
    }

    func refreshAccess() {
        service.refreshAccessibilityStatus(promptIfNeeded: true)
        pullFromService()
    }

    func recoverAccess() {
        service.runAccessRecoveryWizard()
        pullFromService()
    }

    private func pullFromService() {
        isEnabled = service.isEnabled
        capturingKeyboard = service.capturingKeyboard
        accessibilityGranted = service.accessibilityGranted
        inputMonitoringGranted = service.inputMonitoringGranted
        accessActionHint = service.accessActionHint
        selectedProfile = service.selectedProfile
        appearanceMode = service.appearanceMode
    }
}
