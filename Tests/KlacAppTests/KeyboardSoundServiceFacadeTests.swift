#if canImport(XCTest)
import XCTest
@testable import KlacApp

@MainActor
final class KeyboardSoundServiceFacadeTests: XCTestCase {
    func testExportSettingsDelegatesToProfileTransferCoordinator() {
        let profileCoordinator = MockProfileTransferCoordinator()
        let service = makeService(profileCoordinator: profileCoordinator)

        service.exportSettings()

        XCTAssertEqual(profileCoordinator.exportCalls, 1)
        XCTAssertEqual(profileCoordinator.lastExportState?.selectedProfile, service.selectedProfile)
    }

    func testImportSettingsAppliesImportedStateFromCoordinator() {
        let profileCoordinator = MockProfileTransferCoordinator()
        profileCoordinator.importResult = (
            .success(path: "/tmp/in.json"),
            ProfileSettingsState(
                selectedProfile: .mechvibesEGOreo,
                volume: 0.42,
                variation: 0.19,
                playKeyUp: false,
                pressLevel: 1.1,
                releaseLevel: 0.55,
                spaceLevel: 1.05
            )
        )
        let service = makeService(profileCoordinator: profileCoordinator)

        service.importSettings()

        XCTAssertEqual(profileCoordinator.importCalls, 1)
        XCTAssertEqual(service.selectedProfile, .mechvibesEGOreo)
        XCTAssertEqual(service.volume, 0.42, accuracy: 0.0001)
        XCTAssertEqual(service.playKeyUp, false)
    }

    func testExportDebugLogDelegatesToDebugCoordinator() {
        let debugCoordinator = MockDebugLogExportCoordinator()
        debugCoordinator.result = .success(path: "/tmp/debug.log")
        let service = makeService(debugCoordinator: debugCoordinator)
        service.currentOutputDeviceName = "Test Device"

        service.exportDebugLog()

        XCTAssertEqual(debugCoordinator.calls, 1)
        XCTAssertEqual(debugCoordinator.lastSnapshot?.outputDeviceName, "Test Device")
        XCTAssertTrue(debugCoordinator.lastDefaultFileName?.hasPrefix("klac-debug-") == true)
    }

    func testCheckForUpdatesDelegatesToUpdateFlowCoordinator() async {
        let updateFlow = MockUpdateCheckFlowCoordinator()
        updateFlow.presentation = UpdateCheckPresentation(
            statusText: "ok",
            debugMessage: "dbg",
            action: nil
        )
        let metadata = MockAppMetadataProvider(bundleID: "com.example.klac", version: "9.9.9", build: 999)
        let service = makeService(updateFlowCoordinator: updateFlow, appMetadataProvider: metadata)

        service.checkForUpdatesInteractive()
        for _ in 0 ..< 20 {
            await Task.yield()
        }

        XCTAssertEqual(updateFlow.calls, 1)
        XCTAssertEqual(updateFlow.lastCurrentVersion, "9.9.9")
        XCTAssertEqual(updateFlow.lastCurrentBuild, 999)
        XCTAssertEqual(service.updateStatusText, "ok")
    }

    func testOutputDevicePollAppliesAutoPresetForHeadphones() {
        let monitor = MockSystemAudioMonitor()
        let service = makeService(systemAudioMonitor: monitor)

        monitor.emit(SystemAudioPollPayload(
            scalar: 0.42,
            deviceID: 123,
            deviceUID: "bt-headphones",
            deviceName: "Nothing Headphone (1)"
        ))

        XCTAssertEqual(service.currentOutputDeviceName, "Nothing Headphone (1)")
        XCTAssertEqual(service.autoOutputPresetLastApplied, "Наушники")
    }

    func testDeviceSwitchRestoresSnapshotAndMarksDeviceProfile() {
        let suite = "klac.tests.facade.snapshot.restore.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let monitor = MockSystemAudioMonitor()

        let store = SettingsStore(defaults: defaults)
        let snapshot = DeviceSoundSnapshot(
            volume: 0.22,
            variation: 0.33,
            pitchVariation: 0.15,
            pressLevel: 1.0,
            releaseLevel: 0.7,
            spaceLevel: 1.05,
            levelMacLowMid: 0.45,
            levelKbdLowMid: 1.30,
            levelMacHighMid: 0.8,
            levelKbdHighMid: 0.7,
            stackModeEnabled: false,
            limiterEnabled: true,
            limiterDrive: 1.2,
            minInterKeyGapMs: 14,
            releaseDuckingStrength: 0.72,
            releaseDuckingWindowMs: 92,
            releaseTailTightness: 0.38,
            currentOutputDeviceBoost: 1.4
        )
        store.encode(["dev-restore": snapshot], forKey: SettingsKeys.perDeviceSoundSnapshots)

        let service = KeyboardSoundService(
            inputMonitoring: MockKeyboardInputMonitoring(),
            permissionsController: MockPermissionsController(),
            launchAtLoginController: MockLaunchAtLoginController(),
            appRestartController: MockAppRestartController(),
            profileSettingsTransferCoordinator: MockProfileTransferCoordinator(),
            debugLogExportCoordinator: MockDebugLogExportCoordinator(),
            settingsStore: store,
            settingsRepository: SettingsRepository(store: store),
            systemAudioMonitor: monitor,
            alertPresenter: MockAlertPresenter(),
            urlOpener: MockURLOpener(),
            appMetadataProvider: MockAppMetadataProvider(bundleID: "com.test.klac"),
            updateCheckFlowCoordinator: MockUpdateCheckFlowCoordinator()
        )

        monitor.emit(SystemAudioPollPayload(
            scalar: 0.5,
            deviceID: 111,
            deviceUID: "dev-restore",
            deviceName: "USB DAC"
        ))

        XCTAssertEqual(service.autoOutputPresetLastApplied, "Профиль устройства")
        XCTAssertEqual(service.volume, 0.22, accuracy: 0.0001)
        XCTAssertEqual(service.currentOutputDeviceBoost, 1.4, accuracy: 0.0001)
    }

    func testDeviceSwitchWithoutSnapshotFallsBackToAutoPreset() {
        let monitor = MockSystemAudioMonitor()
        let service = makeService(systemAudioMonitor: monitor)

        monitor.emit(SystemAudioPollPayload(
            scalar: 0.5,
            deviceID: 222,
            deviceUID: "dev-speakers",
            deviceName: "MacBook Pro Speakers"
        ))

        XCTAssertEqual(service.autoOutputPresetLastApplied, "Динамики")
    }

    func testInitRestoresPersistedStateFromRepository() {
        let suite = "klac.tests.facade.restore.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defaults.set(0.51, forKey: SettingsKeys.volume)
        defaults.set(0.18, forKey: SettingsKeys.variation)
        defaults.set(false, forKey: SettingsKeys.playKeyUp)
        defaults.set(SoundProfile.mechvibesBoxJade.rawValue, forKey: SettingsKeys.selectedProfile)
        defaults.set(KlacAppearanceMode.dark.rawValue, forKey: SettingsKeys.appearanceMode)

        let store = SettingsStore(defaults: defaults)
        let repository = SettingsRepository(store: store)
        let service = KeyboardSoundService(
            inputMonitoring: MockKeyboardInputMonitoring(),
            permissionsController: MockPermissionsController(),
            launchAtLoginController: MockLaunchAtLoginController(),
            appRestartController: MockAppRestartController(),
            profileSettingsTransferCoordinator: MockProfileTransferCoordinator(),
            debugLogExportCoordinator: MockDebugLogExportCoordinator(),
            settingsStore: store,
            settingsRepository: repository,
            systemAudioMonitor: MockSystemAudioMonitor(),
            alertPresenter: MockAlertPresenter(),
            urlOpener: MockURLOpener(),
            updateCheckFlowCoordinator: MockUpdateCheckFlowCoordinator()
        )

        XCTAssertEqual(service.volume, 0.51, accuracy: 0.0001)
        XCTAssertEqual(service.variation, 0.18, accuracy: 0.0001)
        XCTAssertEqual(service.playKeyUp, false)
        XCTAssertEqual(service.selectedProfile, .mechvibesBoxJade)
        XCTAssertEqual(service.appearanceMode, .dark)
    }

    func testResetPrivacyPermissionsUsesInjectedBundleIdentifier() {
        let permissions = MockPermissionsController()
        let metadata = MockAppMetadataProvider(bundleID: "com.example.klac")
        let service = KeyboardSoundService(
            inputMonitoring: MockKeyboardInputMonitoring(),
            permissionsController: permissions,
            launchAtLoginController: MockLaunchAtLoginController(),
            appRestartController: MockAppRestartController(),
            profileSettingsTransferCoordinator: MockProfileTransferCoordinator(),
            debugLogExportCoordinator: MockDebugLogExportCoordinator(),
            settingsStore: SettingsStore(defaults: UserDefaults(suiteName: "klac.tests.reset.\(UUID().uuidString)")!),
            settingsRepository: nil,
            systemAudioMonitor: MockSystemAudioMonitor(),
            alertPresenter: MockAlertPresenter(),
            urlOpener: MockURLOpener(),
            appMetadataProvider: metadata,
            updateCheckFlowCoordinator: MockUpdateCheckFlowCoordinator()
        )

        service.resetPrivacyPermissions()

        XCTAssertEqual(permissions.resetCalls.count, 2)
        XCTAssertEqual(permissions.resetCalls[0].bundleID, "com.example.klac")
        XCTAssertEqual(permissions.resetCalls[1].bundleID, "com.example.klac")
    }

    func testRunAccessRecoveryWizardTriggersResetAndRestartFlow() {
        let permissions = MockPermissionsController()
        let restart = MockAppRestartController()
        let metadata = MockAppMetadataProvider(bundleID: "com.example.klac")
        let service = KeyboardSoundService(
            inputMonitoring: MockKeyboardInputMonitoring(),
            permissionsController: permissions,
            launchAtLoginController: MockLaunchAtLoginController(),
            appRestartController: restart,
            profileSettingsTransferCoordinator: MockProfileTransferCoordinator(),
            debugLogExportCoordinator: MockDebugLogExportCoordinator(),
            settingsStore: SettingsStore(defaults: UserDefaults(suiteName: "klac.tests.wizard.\(UUID().uuidString)")!),
            settingsRepository: nil,
            systemAudioMonitor: MockSystemAudioMonitor(),
            alertPresenter: MockAlertPresenter(),
            urlOpener: MockURLOpener(),
            appMetadataProvider: metadata,
            accessRecoveryCoordinator: AccessRecoveryCoordinator(scheduler: ImmediateRecoveryScheduler()),
            updateCheckFlowCoordinator: MockUpdateCheckFlowCoordinator()
        )

        service.runAccessRecoveryWizard()

        XCTAssertEqual(permissions.resetCalls.count, 2)
        XCTAssertEqual(restart.calls, 1)
        XCTAssertEqual(service.accessActionHint, "Открыл Универсальный доступ и Мониторинг ввода. После перезапуска включи Klac в обоих списках.")
    }

    private func makeService(
        profileCoordinator: MockProfileTransferCoordinator = MockProfileTransferCoordinator(),
        debugCoordinator: MockDebugLogExportCoordinator = MockDebugLogExportCoordinator(),
        updateFlowCoordinator: MockUpdateCheckFlowCoordinator = MockUpdateCheckFlowCoordinator(),
        systemAudioMonitor: MockSystemAudioMonitor = MockSystemAudioMonitor(),
        appMetadataProvider: MockAppMetadataProvider = MockAppMetadataProvider(bundleID: "com.test.klac"),
        appRestartController: MockAppRestartController = MockAppRestartController(),
        accessRecoveryCoordinator: AccessRecoveryCoordinator = AccessRecoveryCoordinator(scheduler: ImmediateRecoveryScheduler())
    ) -> KeyboardSoundService {
        let suite = "klac.tests.facade.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let store = SettingsStore(defaults: defaults)
        let repository = SettingsRepository(store: store)

        return KeyboardSoundService(
            inputMonitoring: MockKeyboardInputMonitoring(),
            permissionsController: MockPermissionsController(),
            launchAtLoginController: MockLaunchAtLoginController(),
            appRestartController: appRestartController,
            profileSettingsTransferCoordinator: profileCoordinator,
            debugLogExportCoordinator: debugCoordinator,
            settingsStore: store,
            settingsRepository: repository,
            systemAudioMonitor: systemAudioMonitor,
            alertPresenter: MockAlertPresenter(),
            urlOpener: MockURLOpener(),
            appMetadataProvider: appMetadataProvider,
            accessRecoveryCoordinator: accessRecoveryCoordinator,
            updateCheckFlowCoordinator: updateFlowCoordinator
        )
    }
}

private final class MockKeyboardInputMonitoring: KeyboardInputMonitoring {
    var onEvent: ((KeyEventType, Int, Bool) -> Void)?
    func start() -> Bool { false }
    func stop() {}
}

private final class MockPermissionsController: PermissionsControlling {
    var resetCalls: [(service: String, bundleID: String)] = []

    func refreshStatus(promptIfNeeded _: Bool) -> PermissionsStatus {
        PermissionsStatus(accessibilityGranted: false, inputMonitoringGranted: false)
    }
    func openAccessibilitySettings() {}
    func openInputMonitoringSettings() {}
    func resetTCC(service: String, bundleID: String) {
        resetCalls.append((service, bundleID))
    }
}

private struct MockLaunchAtLoginController: LaunchAtLoginControlling {
    func setEnabled(_: Bool) throws {}
}

private final class MockAppRestartController: AppRestartControlling {
    var calls = 0

    func restartApplication(onManualRestartRequired _: @escaping () -> Void) {
        calls += 1
    }
}

private final class MockProfileTransferCoordinator: ProfileSettingsTransferCoordinating {
    var exportCalls = 0
    var importCalls = 0
    var lastExportState: ProfileSettingsState?
    var importResult: (ProfileSettingsTransferResult, ProfileSettingsState?) = (.cancelled, nil)

    func exportSettings(from state: ProfileSettingsState) -> ProfileSettingsTransferResult {
        exportCalls += 1
        lastExportState = state
        return .success(path: "/tmp/out.json")
    }

    func importSettings(fallbackProfile _: SoundProfile) -> (ProfileSettingsTransferResult, ProfileSettingsState?) {
        importCalls += 1
        return importResult
    }
}

private final class MockDebugLogExportCoordinator: DebugLogExportCoordinating {
    var calls = 0
    var result: DebugLogExportResult = .cancelled
    var lastSnapshot: DiagnosticsRuntimeSnapshot?
    var lastDefaultFileName: String?

    func exportDebugLog(
        runtimeSnapshot: DiagnosticsRuntimeSnapshot,
        debugLogService _: DebugLogService,
        defaultFileName: String
    ) -> DebugLogExportResult {
        calls += 1
        lastSnapshot = runtimeSnapshot
        lastDefaultFileName = defaultFileName
        return result
    }
}

private final class MockUpdateCheckFlowCoordinator: UpdateCheckFlowCoordinating {
    var calls = 0
    var lastCurrentVersion: String?
    var lastCurrentBuild: Int?
    var presentation = UpdateCheckPresentation(statusText: "idle", debugMessage: "idle", action: nil)

    func run(currentVersion: String, currentBuild: Int) async -> UpdateCheckPresentation {
        calls += 1
        lastCurrentVersion = currentVersion
        lastCurrentBuild = currentBuild
        return presentation
    }
}

@MainActor
private final class MockSystemAudioMonitor: SystemAudioMonitoring {
    private var onPoll: ((SystemAudioPollPayload) -> Void)?

    func start(interval _: TimeInterval, onPoll: @escaping (SystemAudioPollPayload) -> Void) {
        self.onPoll = onPoll
    }
    func stop() {}
    func ensureInterval(_: TimeInterval, onPoll: @escaping (SystemAudioPollPayload) -> Void) {
        self.onPoll = onPoll
    }
    func resetStuckPollIfNeeded(now _: CFAbsoluteTime, threshold _: TimeInterval) -> Bool { false }

    func emit(_ payload: SystemAudioPollPayload) {
        onPoll?(payload)
    }
}

private struct MockAlertPresenter: InfoAlertPresenting {
    func showInfoAlert(title _: String, message _: String) {}
}

private struct MockURLOpener: URLOpening {
    func open(_: URL) {}
}

private struct MockAppMetadataProvider: AppMetadataProviding {
    let bundleID: String?
    var version: String = "2.1.4"
    var build: Int = 214

    func currentAppVersion() -> String { version }
    func currentAppBuildNumber() -> Int { build }
    func resolveBundleIdentifier() -> String? { bundleID }
}

private struct ImmediateRecoveryScheduler: RecoveryScheduling {
    func schedule(after _: TimeInterval, _ block: @escaping () -> Void) {
        block()
    }
}
#endif
