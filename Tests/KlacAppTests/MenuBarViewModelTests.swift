#if canImport(XCTest)
import XCTest
@testable import KlacApp

@MainActor
final class MenuBarViewModelTests: XCTestCase {
    func testInitialStatePulledFromService() {
        let service = MockMenuBarService()
        service.isEnabled = false
        service.capturingKeyboard = true
        service.accessibilityGranted = true
        service.inputMonitoringGranted = true
        service.accessActionHint = "hint"
        service.selectedProfile = .mechvibesHyperXAqua
        service.appearanceMode = .dark

        let viewModel = MenuBarViewModel(service: service)

        XCTAssertEqual(viewModel.isEnabled, false)
        XCTAssertEqual(viewModel.capturingKeyboard, true)
        XCTAssertEqual(viewModel.accessibilityGranted, true)
        XCTAssertEqual(viewModel.inputMonitoringGranted, true)
        XCTAssertEqual(viewModel.accessActionHint, "hint")
        XCTAssertEqual(viewModel.selectedProfile, .mechvibesHyperXAqua)
        XCTAssertEqual(viewModel.appearanceMode, .dark)
    }

    func testSetEnabledDelegatesStartAndStop() {
        let service = MockMenuBarService()
        let viewModel = MenuBarViewModel(service: service)

        viewModel.setEnabled(true)
        viewModel.setEnabled(false)

        XCTAssertEqual(service.startCalls, 1)
        XCTAssertEqual(service.stopCalls, 1)
    }

    func testSelectProfileDelegatesToService() {
        let service = MockMenuBarService()
        let viewModel = MenuBarViewModel(service: service)

        viewModel.selectProfile(.mechvibesBoxJade)

        XCTAssertEqual(service.selectedProfile, .mechvibesBoxJade)
    }

    func testChangePublisherRefreshesPublishedState() async {
        let service = MockMenuBarService()
        let viewModel = MenuBarViewModel(service: service)
        XCTAssertEqual(viewModel.selectedProfile, .kalihBoxWhite)

        service.selectedProfile = .mechvibesEGCrystalPurple
        service.appearanceMode = .light
        service.changePublisher.send()

        for _ in 0 ..< 20 {
            await Task.yield()
        }

        XCTAssertEqual(viewModel.selectedProfile, .mechvibesEGCrystalPurple)
        XCTAssertEqual(viewModel.appearanceMode, .light)
    }

    func testCheckForUpdatesDelegates() {
        let service = MockMenuBarService()
        let viewModel = MenuBarViewModel(service: service)

        viewModel.checkForUpdates()

        XCTAssertEqual(service.checkForUpdatesCalls, 1)
    }

    func testRefreshAccessDelegatesWithPrompt() {
        let service = MockMenuBarService()
        let viewModel = MenuBarViewModel(service: service)

        viewModel.refreshAccess()

        XCTAssertEqual(service.refreshStatusCalls, [true])
    }

    func testRecoverAccessDelegates() {
        let service = MockMenuBarService()
        let viewModel = MenuBarViewModel(service: service)

        viewModel.recoverAccess()

        XCTAssertEqual(service.runRecoveryCalls, 1)
    }
}

@MainActor
private final class MockMenuBarService: MenuBarServiceProtocol {
    let changePublisher = ObservableObjectPublisher()

    var isEnabled: Bool = true
    var capturingKeyboard: Bool = false
    var accessibilityGranted: Bool = false
    var inputMonitoringGranted: Bool = false
    var accessActionHint: String?
    var selectedProfile: SoundProfile = .kalihBoxWhite
    var appearanceMode: KlacAppearanceMode = .system

    var startCalls = 0
    var stopCalls = 0
    var checkForUpdatesCalls = 0
    var refreshStatusCalls: [Bool] = []
    var runRecoveryCalls = 0

    func start() {
        startCalls += 1
    }

    func stop() {
        stopCalls += 1
    }

    func makeAdvancedSettingsViewModel() -> AdvancedSettingsViewModel {
        preconditionFailure("Not used in MenuBarViewModel tests")
    }

    func checkForUpdatesInteractive() {
        checkForUpdatesCalls += 1
    }

    func refreshAccessibilityStatus(promptIfNeeded: Bool) {
        refreshStatusCalls.append(promptIfNeeded)
    }

    func runAccessRecoveryWizard() {
        runRecoveryCalls += 1
    }
}

#endif
