import Combine
import Foundation

@MainActor
protocol MenuBarServiceProtocol: AnyObject {
    var changePublisher: AnyPublisher<Void, Never> { get }

    var isEnabled: Bool { get set }
    var capturingKeyboard: Bool { get }
    var accessibilityGranted: Bool { get }
    var inputMonitoringGranted: Bool { get }
    var accessActionHint: String? { get }
    var selectedProfile: SoundProfile { get set }
    var appearanceMode: KlacAppearanceMode { get }

    func start()
    func stop()
    func makeAdvancedSettingsViewModel() -> AdvancedSettingsViewModel
    func checkForUpdatesInteractive()
    func refreshAccessibilityStatus(promptIfNeeded: Bool)
    func runAccessRecoveryWizard()
}

extension KeyboardSoundService: MenuBarServiceProtocol {
    var changePublisher: AnyPublisher<Void, Never> { objectWillChange.eraseToAnyPublisher() }

    func makeAdvancedSettingsViewModel() -> AdvancedSettingsViewModel {
        AdvancedSettingsViewModel(service: self)
    }
}
