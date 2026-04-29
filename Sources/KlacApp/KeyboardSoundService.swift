import AppKit
import CoreAudio
import Foundation

@MainActor
final class KeyboardSoundService: ObservableObject {
    typealias ABFeature = KlacABFeature
    typealias AppearanceMode = KlacAppearanceMode
    typealias OutputPresetMode = KlacOutputPresetMode
    typealias LevelTuningMode = KlacLevelTuningMode

    @Published var isEnabled = true {
        didSet { syncSettingFlag(isEnabled, key: SettingsKeys.isEnabled) }
    }
    @Published var accessibilityGranted = false
    @Published var inputMonitoringGranted = false
    @Published var accessActionHint: String?
    @Published var volume: Double = 0.75 {
        didSet { syncSoundScalar(volume, key: SettingsKeys.volume, apply: { soundEngine.masterVolume = $0 }) }
    }
    @Published var variation: Double = 0.3 {
        didSet { syncSoundScalar(variation, key: SettingsKeys.variation, apply: { soundEngine.variation = $0 }) }
    }
    @Published var pitchVariation: Double = 0.22 {
        didSet {
            syncClampedSoundScalar(
                pitchVariation,
                key: SettingsKeys.pitchVariation,
                range: 0.0 ... 0.6,
                apply: { self.soundEngine.pitchVariationAmount = $0 },
                afterApply: { self.soundEngine.reloadCurrentProfile() }
            )
        }
    }
    @Published var playKeyUp = true {
        didSet { syncPlayKeyUp(playKeyUp) }
    }
    @Published var pressLevel: Double = 1.0 {
        didSet { syncSoundScalar(pressLevel, key: SettingsKeys.pressLevel, apply: { soundEngine.pressLevel = $0 }) }
    }
    @Published var releaseLevel: Double = 0.65 {
        didSet { syncSoundScalar(releaseLevel, key: SettingsKeys.releaseLevel, apply: { soundEngine.releaseLevel = $0 }) }
    }
    @Published var spaceLevel: Double = 1.1 {
        didSet { syncSoundScalar(spaceLevel, key: SettingsKeys.spaceLevel, apply: { soundEngine.spaceLevel = $0 }) }
    }
    @Published var selectedProfile: SoundProfile = .kalihBoxWhite {
        didSet { syncSelectedProfile(from: oldValue, to: selectedProfile) }
    }
    @Published var autoProfileTuningEnabled = true {
        didSet { syncSettingFlag(autoProfileTuningEnabled, key: SettingsKeys.autoProfileTuningEnabled) }
    }
    @Published var profilePresetLastApplied = "—"
    @Published var launchAtLogin = false {
        didSet { syncLaunchAtLoginFlag(launchAtLogin, key: SettingsKeys.launchAtLogin) }
    }
    @Published var dynamicCompensationEnabled = false {
        didSet { syncDynamicCompensationFlag(dynamicCompensationEnabled, key: SettingsKeys.dynamicCompensationEnabled) }
    }
    @Published var compensationStrength: Double = 1.0 {
        didSet { syncCompensationScalar(compensationStrength, key: SettingsKeys.compensationStrength) }
    }
    @Published var levelMacLow: Double = 0.30 {
        didSet { syncCompensationScalar(levelMacLow, key: SettingsKeys.levelMacLow, clampedTo: 0.05 ... 0.90) }
    }
    @Published var levelKbdLow: Double = 1.60 {
        didSet { syncCompensationScalar(levelKbdLow, key: SettingsKeys.levelKbdLow, clampedTo: 0.20 ... 4.00) }
    }
    @Published var levelMacLowMid: Double = 0.45 {
        didSet { syncCompensationScalar(levelMacLowMid, key: SettingsKeys.levelMacLowMid, clampedTo: 0.08 ... 0.93) }
    }
    @Published var levelKbdLowMid: Double = 1.30 {
        didSet { syncCompensationScalar(levelKbdLowMid, key: SettingsKeys.levelKbdLowMid, clampedTo: 0.20 ... 4.00) }
    }
    @Published var levelMacMid: Double = 0.60 {
        didSet { syncCompensationScalar(levelMacMid, key: SettingsKeys.levelMacMid, clampedTo: 0.05 ... 0.95) }
    }
    @Published var levelKbdMid: Double = 1.00 {
        didSet { syncCompensationScalar(levelKbdMid, key: SettingsKeys.levelKbdMid, clampedTo: 0.20 ... 4.00) }
    }
    @Published var levelMacHighMid: Double = 0.80 {
        didSet { syncCompensationScalar(levelMacHighMid, key: SettingsKeys.levelMacHighMid, clampedTo: 0.10 ... 0.98) }
    }
    @Published var levelKbdHighMid: Double = 0.70 {
        didSet { syncCompensationScalar(levelKbdHighMid, key: SettingsKeys.levelKbdHighMid, clampedTo: 0.20 ... 4.00) }
    }
    @Published var levelMacHigh: Double = 1.00 {
        didSet { syncCompensationScalar(levelMacHigh, key: SettingsKeys.levelMacHigh, clampedTo: 0.10 ... 1.00) }
    }
    @Published var levelKbdHigh: Double = 0.45 {
        didSet { syncCompensationScalar(levelKbdHigh, key: SettingsKeys.levelKbdHigh, clampedTo: 0.20 ... 4.00) }
    }
    @Published var strictVolumeNormalizationEnabled = true {
        didSet { syncStrictNormalizationFlag(strictVolumeNormalizationEnabled, key: SettingsKeys.strictVolumeNormalizationEnabled) }
    }
    @Published var levelTuningMode: LevelTuningMode = .curve {
        didSet { syncCompensationMode(levelTuningMode.rawValue, key: SettingsKeys.levelTuningMode) }
    }
    @Published var autoNormalizeTargetAt100: Double = 0.45 {
        didSet { syncCompensationScalar(autoNormalizeTargetAt100, key: SettingsKeys.autoNormalizeTargetAt100, clampedTo: 0.20 ... 1.20) }
    }
    @Published var typingAdaptiveEnabled = false {
        didSet { syncTypingAdaptationFlag(typingAdaptiveEnabled, key: SettingsKeys.typingAdaptiveEnabled) }
    }
    @Published var stackModeEnabled = false {
        didSet { syncSoundFlag(stackModeEnabled, key: SettingsKeys.stackModeEnabled, apply: { soundEngine.stackModeEnabled = $0 }) }
    }
    @Published var stackDensity: Double = 0.55 {
        didSet { syncSoundScalar(stackDensity, key: SettingsKeys.stackDensity, apply: { soundEngine.stackDensity = $0 }) }
    }
    @Published var layerThresholdSlam: Double = 0.045 {
        didSet { syncLayerThreshold(layerThresholdSlam, key: SettingsKeys.layerThresholdSlam) }
    }
    @Published var layerThresholdHard: Double = 0.085 {
        didSet { syncLayerThreshold(layerThresholdHard, key: SettingsKeys.layerThresholdHard) }
    }
    @Published var layerThresholdMedium: Double = 0.145 {
        didSet { syncLayerThreshold(layerThresholdMedium, key: SettingsKeys.layerThresholdMedium) }
    }
    @Published var minInterKeyGapMs: Double = 14 {
        didSet {
            syncClampedSoundScalar(
                minInterKeyGapMs,
                key: SettingsKeys.minInterKeyGapMs,
                range: 0 ... 45,
                apply: { soundEngine.minInterKeyGapMs = $0 }
            )
        }
    }
    @Published var releaseDuckingStrength: Double = 0.72 {
        didSet {
            syncClampedSoundScalar(
                releaseDuckingStrength,
                key: SettingsKeys.releaseDuckingStrength,
                range: 0 ... 1,
                apply: { soundEngine.releaseDuckingStrength = $0 }
            )
        }
    }
    @Published var releaseDuckingWindowMs: Double = 92 {
        didSet {
            syncClampedSoundScalar(
                releaseDuckingWindowMs,
                key: SettingsKeys.releaseDuckingWindowMs,
                range: 20 ... 180,
                apply: { soundEngine.releaseDuckingWindowMs = $0 }
            )
        }
    }
    @Published var releaseTailTightness: Double = 0.38 {
        didSet {
            syncClampedSoundScalar(
                releaseTailTightness,
                key: SettingsKeys.releaseTailTightness,
                range: 0 ... 1,
                apply: { soundEngine.releaseTailTightness = $0 }
            )
        }
    }
    @Published var limiterEnabled = true {
        didSet { syncSoundFlag(limiterEnabled, key: SettingsKeys.limiterEnabled, apply: { soundEngine.limiterEnabled = $0 }) }
    }
    @Published var limiterDrive: Double = 1.2 {
        didSet { syncSoundScalar(limiterDrive, key: SettingsKeys.limiterDrive, apply: { soundEngine.limiterDrive = $0 }) }
    }
    @Published var typingCPS: Double = 0
    @Published var typingWPM: Double = 0
    @Published var liveDynamicGain: Double = 1.0
    @Published var liveTypingGain: Double = 1.0
    @Published var detectedSystemVolumePercent: Double = 100.0
    @Published var detectedSystemVolumeAvailable = false
    @Published var abFeature: ABFeature = .core
    @Published var isABPlaying = false
    @Published var currentOutputDeviceName = "Системное устройство"
    @Published var currentOutputDeviceBoost: Double = 1.0 {
        didSet {
            saveCurrentDeviceBoost()
            updateDynamicCompensation()
        }
    }
    @Published var autoOutputPresetEnabled = true {
        didSet { syncSettingFlag(autoOutputPresetEnabled, key: SettingsKeys.autoOutputPresetEnabled) }
    }
    @Published var perDeviceSoundProfileEnabled = true {
        didSet {
            syncSettingFlag(perDeviceSoundProfileEnabled, key: SettingsKeys.perDeviceSoundProfileEnabled) {
                self.persistPerDeviceSnapshotIfNeeded()
            }
        }
    }
    @Published var currentOutputPresetMode: OutputPresetMode = .auto {
        didSet {
            guard autoOutputPresetEnabled else { return }
            switch currentOutputPresetMode {
            case .auto:
                applyAutoOutputPresetIfNeeded(deviceUID: currentOutputDeviceUID, deviceName: currentOutputDeviceName)
            case .headphones:
                applyHeadphonesPreset()
            case .speakers:
                applySpeakersPreset()
            }
        }
    }
    @Published var autoOutputPresetLastApplied = "—"
    @Published var updateCheckInProgress = false
    @Published var updateStatusText = "—"
    @Published var liveVelocityLayer = "medium"
    @Published var manifestValidationSummary = "Проверка пака не запускалась"
    @Published var manifestValidationIssues: [String] = []
    @Published var stressTestInProgress = false
    @Published var stressTestProgress: Double = 0
    @Published var stressTestStatus = "Не запускался"
    @Published var debugLogPreview = "Лог пока пуст."
    @Published var appearanceMode: AppearanceMode = .system {
        didSet { syncSettingString(appearanceMode.rawValue, key: SettingsKeys.appearanceMode) }
    }

    private let soundEngine = ClickSoundEngine()
    private let inputMonitor: KeyboardInputMonitorCoordinator
    @Published var capturingKeyboard = false
    private let settingsStore: SettingsStore
    private let settingsRepository: SettingsRepository
    private let updateCheckFlowCoordinator: any UpdateCheckFlowCoordinating
    private let debugLogService = DebugLogService(capacity: 1200)
    private let persistentDebugLogService = PersistentDebugLogService()
    private let diagnosticsSnapshotFactory = DiagnosticsRuntimeSnapshotFactory()
    private let profileSettingsTransferCoordinator: any ProfileSettingsTransferCoordinating
    private let debugLogExportCoordinator: any DebugLogExportCoordinating
    private let systemAudioMonitor: any SystemAudioMonitoring
    private struct RuntimeState {
        var lastSystemVolume: Double = 1.0
        var lastOutputDeviceID: AudioObjectID = 0
        var currentOutputDeviceUID: String = ""
        var lastAutoPresetDeviceUID: String = ""
        var hasPersistedPrimarySettings: Bool = false
        var initialOutputDeviceResolved: Bool = false
    }
    private var runtimeState = RuntimeState()
    private var perDeviceSnapshotRuntime: PerDeviceSnapshotRuntimeCoordinator
    private var perProfileSoundSnapshots: [String: ProfileSoundSnapshot]
    private var isApplyingProfileSnapshot = false
    private var failSafeTimer: Timer?
    private let typingMetricsService = TypingMetricsService()
    private var appWillTerminateObserver: NSObjectProtocol?
    private var isRestoringPersistedState = false
    private let permissionsController: PermissionsControlling
    private let launchAtLoginController: LaunchAtLoginControlling
    private let appRestartController: AppRestartControlling
    private let alertPresenter: InfoAlertPresenting
    private let urlOpener: URLOpening
    private let appMetadataProvider: AppMetadataProviding
    private let accessRecoveryCoordinator: AccessRecoveryCoordinator
    private var lastSystemVolume: Double {
        get { runtimeState.lastSystemVolume }
        set { runtimeState.lastSystemVolume = newValue }
    }

    private var lastOutputDeviceID: AudioObjectID {
        get { runtimeState.lastOutputDeviceID }
        set { runtimeState.lastOutputDeviceID = newValue }
    }

    private var currentOutputDeviceUID: String {
        get { runtimeState.currentOutputDeviceUID }
        set { runtimeState.currentOutputDeviceUID = newValue }
    }

    private var lastAutoPresetDeviceUID: String {
        get { runtimeState.lastAutoPresetDeviceUID }
        set { runtimeState.lastAutoPresetDeviceUID = newValue }
    }

    private var hasPersistedPrimarySettings: Bool {
        get { runtimeState.hasPersistedPrimarySettings }
        set { runtimeState.hasPersistedPrimarySettings = newValue }
    }

    private var initialOutputDeviceResolved: Bool {
        get { runtimeState.initialOutputDeviceResolved }
        set { runtimeState.initialOutputDeviceResolved = newValue }
    }

    init(
        inputMonitoring: KeyboardInputMonitoring = GlobalKeyEventTap(),
        permissionsController: PermissionsControlling = SystemPermissionsController(),
        launchAtLoginController: LaunchAtLoginControlling = SystemLaunchAtLoginController(),
        appRestartController: AppRestartControlling = SystemAppRestartController(),
        fileDialogService: FileDialogPresenting = SystemFileDialogService(),
        fileReadWriter: FileReadWriting = FileSystemReadWriter(),
        profileSettingsTransferCoordinator: (any ProfileSettingsTransferCoordinating)? = nil,
        debugLogExportCoordinator: (any DebugLogExportCoordinating)? = nil,
        settingsStore: SettingsStore = SettingsStore(),
        settingsRepository: SettingsRepository? = nil,
        systemAudioMonitor: (any SystemAudioMonitoring)? = nil,
        alertPresenter: InfoAlertPresenting = SystemInfoAlertPresenter(),
        urlOpener: URLOpening = SystemURLOpener(),
        appMetadataProvider: AppMetadataProviding = SystemAppMetadataProvider(),
        accessRecoveryCoordinator: AccessRecoveryCoordinator = AccessRecoveryCoordinator(),
        updateCheckFlowCoordinator: (any UpdateCheckFlowCoordinating)? = nil
    ) {
        inputMonitor = KeyboardInputMonitorCoordinator(monitor: inputMonitoring)
        self.permissionsController = permissionsController
        self.launchAtLoginController = launchAtLoginController
        self.appRestartController = appRestartController
        self.settingsStore = settingsStore
        self.settingsRepository = settingsRepository ?? SettingsRepository(store: settingsStore)
        self.alertPresenter = alertPresenter
        self.urlOpener = urlOpener
        self.appMetadataProvider = appMetadataProvider
        self.accessRecoveryCoordinator = accessRecoveryCoordinator
        let defaultUpdateFlow = UpdateCheckFlowCoordinator(
            updateChecker: UpdateCheckService(fetchLatestRelease: {
                try await KlacUpdateService(owner: "squazaryu", repository: "klac-app").fetchLatestRelease()
            })
        )
        self.updateCheckFlowCoordinator = updateCheckFlowCoordinator ?? defaultUpdateFlow
        self.profileSettingsTransferCoordinator = profileSettingsTransferCoordinator ?? ProfileSettingsTransferCoordinator(
            transferService: .init(),
            fileDialogs: fileDialogService,
            fileIO: fileReadWriter
        )
        self.debugLogExportCoordinator = debugLogExportCoordinator ?? DebugLogExportCoordinator(
            diagnosticsCoordinator: .init(),
            fileDialogs: fileDialogService,
            fileIO: fileReadWriter
        )
        self.systemAudioMonitor = systemAudioMonitor ?? SystemAudioMonitor()
        let persistedState = self.settingsRepository.loadState()
        let snapshotService = PerDeviceSnapshotService(
            settingsStore: self.settingsStore,
            snapshots: persistedState.perDeviceSoundSnapshots,
            boosts: persistedState.outputDeviceBoosts
        )
        perDeviceSnapshotRuntime = PerDeviceSnapshotRuntimeCoordinator(snapshotService: snapshotService)
        perProfileSoundSnapshots = self.settingsStore.decode(
            [String: ProfileSoundSnapshot].self,
            forKey: SettingsKeys.perProfileSoundSnapshots
        ) ?? [:]
        hasPersistedPrimarySettings = persistedState.hasPrimaryPersistedSettings
        restorePersistedState(persistedState)
        configureSoundEngine()
        startRuntimeServices()
        configureEventTap()
        updateLaunchAtLogin()
        registerTerminationObserver()
        initializePersistentDiagnosticsSession()
    }

    private func restorePersistedState(_ state: SettingsRepository.State) {
        let plan = PersistedStateCoordinator.makePlan(from: state)
        isRestoringPersistedState = true
        isEnabled = plan.isEnabled
        applyPersistedSoundState(plan.sound)
        applyPersistedCompensationState(plan.compensation)
        applyPersistedSystemState(plan.system)
        isRestoringPersistedState = false
    }

    private func applyPersistedSoundState(_ plan: PersistedSoundStatePlan) {
        autoProfileTuningEnabled = plan.autoProfileTuningEnabled
        applySoundStatePatch(SoundStatePatchMapper.persistedSoundPatch(from: plan))
        stackDensity = plan.stackDensity
        layerThresholdSlam = plan.layerThresholdSlam
        layerThresholdHard = plan.layerThresholdHard
        layerThresholdMedium = plan.layerThresholdMedium
    }

    private func applyPersistedCompensationState(_ plan: PersistedCompensationStatePlan) {
        applyCompensationSettings(CompensationSettings(
            levelMacLow: plan.levelMacLow,
            levelKbdLow: plan.levelKbdLow,
            levelMacLowMid: plan.levelMacLowMid,
            levelKbdLowMid: plan.levelKbdLowMid,
            levelMacMid: plan.levelMacMid,
            levelKbdMid: plan.levelKbdMid,
            levelMacHighMid: plan.levelMacHighMid,
            levelKbdHighMid: plan.levelKbdHighMid,
            levelMacHigh: plan.levelMacHigh,
            levelKbdHigh: plan.levelKbdHigh,
            dynamicCompensationEnabled: plan.dynamicCompensationEnabled,
            strictVolumeNormalizationEnabled: plan.strictVolumeNormalizationEnabled
        ))
        compensationStrength = plan.compensationStrength
        levelTuningMode = plan.levelTuningMode
        autoNormalizeTargetAt100 = plan.autoNormalizeTargetAt100
        typingAdaptiveEnabled = plan.typingAdaptiveEnabled
    }

    private func applyPersistedSystemState(_ plan: PersistedSystemStatePlan) {
        launchAtLogin = plan.launchAtLogin
        autoOutputPresetEnabled = plan.autoOutputPresetEnabled
        perDeviceSoundProfileEnabled = plan.perDeviceSoundProfileEnabled
        appearanceMode = plan.appearanceMode
    }

    private func configureSoundEngine() {
        soundEngine.masterVolume = Float(volume)
        soundEngine.variation = Float(variation)
        soundEngine.pitchVariationAmount = Float(pitchVariation)
        soundEngine.pressLevel = Float(pressLevel)
        soundEngine.releaseLevel = Float(releaseLevel)
        soundEngine.spaceLevel = Float(spaceLevel)
        soundEngine.limiterEnabled = limiterEnabled
        soundEngine.limiterDrive = Float(limiterDrive)
        soundEngine.stackModeEnabled = stackModeEnabled
        soundEngine.stackDensity = Float(stackDensity)
        soundEngine.strictLevelingEnabled = strictVolumeNormalizationEnabled
        soundEngine.minInterKeyGapMs = Float(minInterKeyGapMs)
        soundEngine.releaseDuckingStrength = Float(releaseDuckingStrength)
        soundEngine.releaseDuckingWindowMs = Float(releaseDuckingWindowMs)
        soundEngine.releaseTailTightness = Float(releaseTailTightness)
        applyLayerThresholds()
        soundEngine.onVelocityLayerChanged = makeVelocityLayerChangedCallback()
        soundEngine.onManifestValidation = makeManifestValidationCallback()
        soundEngine.onDiagnostic = makeAudioDiagnosticCallback()
        soundEngine.setProfile(selectedProfile)
    }

    private func startRuntimeServices() {
        updateSystemVolumeMonitoringState()
        updateTypingDecayMonitoringState()
        startFailSafeMonitoring()
        updateDynamicCompensation()
        updateTypingAdaptation()
        refreshAccessibilityStatus(promptIfNeeded: false)
        recordDebug("Service initialized. profile=\(selectedProfile.rawValue), enabled=\(isEnabled)")
    }

    private func configureEventTap() {
        inputMonitor.setEventHandler { [weak self] type, keyCode, isAutorepeat in
            self?.handleKeyboardInputEvent(type: type, keyCode: keyCode, isAutorepeat: isAutorepeat)
        }
    }

    private func handleKeyboardInputEvent(type: KeyEventType, keyCode: Int, isAutorepeat: Bool) {
        KeyboardInputRuntimeCoordinator.handle(
            context: KeyboardInputEventContext(
                isEnabled: isEnabled,
                playKeyUp: playKeyUp,
                type: type,
                keyCode: keyCode,
                isAutorepeat: isAutorepeat
            ),
            dependencies: makeKeyboardInputRuntimeDependencies()
        )
    }

    private func registerTerminationObserver() {
        appWillTerminateObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.persistentDebugLogService.markGracefulShutdown()
                self?.persistPerDeviceSnapshotIfNeeded()
            }
        }
    }

    private func initializePersistentDiagnosticsSession() {
        let hadUngracefulExit = persistentDebugLogService.beginSession(
            appVersion: appMetadataProvider.currentAppVersion(),
            buildNumber: appMetadataProvider.currentAppBuildNumber()
        )
        if hadUngracefulExit {
            recordDebug("Detected ungraceful previous shutdown (possible crash/force-close).")
        }
    }

    deinit {
        if let appWillTerminateObserver {
            NotificationCenter.default.removeObserver(appWillTerminateObserver)
        }
        failSafeTimer?.invalidate()
    }

    private func syncSoundScalar(_ value: Double, key: String, apply: (Float) -> Void) {
        settingsStore.set(value, forKey: key)
        apply(Float(value))
        persistPerDeviceSnapshotIfNeeded()
        persistCurrentProfileSnapshotIfNeeded()
    }

    private func syncSettingFlag(_ value: Bool, key: String, after: (() -> Void)? = nil) {
        settingsStore.set(value, forKey: key)
        after?()
    }

    private func syncSettingString(_ value: String, key: String, after: (() -> Void)? = nil) {
        settingsStore.set(value, forKey: key)
        after?()
    }

    private func syncClampedSoundScalar(
        _ value: Double,
        key: String,
        range: ClosedRange<Double>,
        apply: (Float) -> Void,
        afterApply: (() -> Void)? = nil
    ) {
        let clamped = value.clamped(to: range)
        settingsStore.set(clamped, forKey: key)
        apply(Float(clamped))
        afterApply?()
        persistPerDeviceSnapshotIfNeeded()
        persistCurrentProfileSnapshotIfNeeded()
    }

    private func syncSoundFlag(_ value: Bool, key: String, apply: (Bool) -> Void) {
        settingsStore.set(value, forKey: key)
        apply(value)
        persistPerDeviceSnapshotIfNeeded()
        persistCurrentProfileSnapshotIfNeeded()
    }

    private func syncPlayKeyUp(_ enabled: Bool) {
        syncSettingFlag(enabled, key: SettingsKeys.playKeyUp)
        persistCurrentProfileSnapshotIfNeeded()
    }

    private func syncCompensationScalar(_ value: Double, key: String, clampedTo range: ClosedRange<Double>? = nil) {
        let persisted = range.map { value.clamped(to: $0) } ?? value
        settingsStore.set(persisted, forKey: key)
        updateDynamicCompensation()
    }

    private func syncCompensationMode(_ rawValue: String, key: String) {
        settingsStore.set(rawValue, forKey: key)
        updateDynamicCompensation()
    }

    private func syncLayerThreshold(_ value: Double, key: String) {
        settingsStore.set(value, forKey: key)
        applyLayerThresholds()
        persistCurrentProfileSnapshotIfNeeded()
    }

    private func syncDynamicCompensationFlag(_ enabled: Bool, key: String) {
        settingsStore.set(enabled, forKey: key)
        updateSystemVolumeMonitoringState()
        updateDynamicCompensation()
    }

    private func syncStrictNormalizationFlag(_ enabled: Bool, key: String) {
        settingsStore.set(enabled, forKey: key)
        soundEngine.strictLevelingEnabled = enabled
        updateDynamicCompensation()
        updateTypingDecayMonitoringState()
        updateTypingAdaptation()
    }

    private func syncTypingAdaptationFlag(_ enabled: Bool, key: String) {
        settingsStore.set(enabled, forKey: key)
        updateTypingDecayMonitoringState()
        updateTypingAdaptation()
    }

    private func syncLaunchAtLoginFlag(_ enabled: Bool, key: String) {
        settingsStore.set(enabled, forKey: key)
        updateLaunchAtLogin()
    }

    private func syncSelectedProfile(from previousProfile: SoundProfile, to profile: SoundProfile) {
        if !isRestoringPersistedState, !isApplyingProfileSnapshot, previousProfile != profile {
            persistProfileSnapshot(for: previousProfile)
        }

        soundEngine.setProfile(profile)

        let restoredFromProfileSnapshot = restoreProfileSnapshot(for: profile)
        if !restoredFromProfileSnapshot, !isRestoringPersistedState, autoProfileTuningEnabled {
            applyProfileSoundPreset(for: profile)
        }
        if !isRestoringPersistedState {
            settingsStore.set(profile.rawValue, forKey: SettingsKeys.selectedProfile)
        }
    }

    func start() {
        // Avoid forcing the system consent prompt on every launch.
        // User can trigger an explicit prompt via the "Проверить" action.
        let outcome = KeyboardCaptureRuntimeCoordinator.start(
            dependencies: makeKeyboardCaptureStartDependencies()
        )
        accessibilityGranted = outcome.accessibilityGranted
        inputMonitoringGranted = outcome.inputMonitoringGranted
        capturingKeyboard = outcome.capturingKeyboard
        recordDebug("Privacy status refreshed. ax=\(accessibilityGranted), input=\(inputMonitoringGranted), capturing=\(capturingKeyboard)")
        recordDebug("Keyboard capture started. capturing=\(capturingKeyboard), ax=\(accessibilityGranted), input=\(inputMonitoringGranted)")
    }

    func stop() {
        KeyboardCaptureRuntimeCoordinator.stop(
            dependencies: makeKeyboardCaptureStopDependencies()
        )
        capturingKeyboard = false
        recordDebug("Keyboard capture stopped")
    }

    func refreshAccessibilityStatus(promptIfNeeded: Bool) {
        let outcome = KeyboardCaptureRuntimeCoordinator.refresh(
            promptIfNeeded: promptIfNeeded,
            isEnabled: isEnabled,
            currentCapturingKeyboard: capturingKeyboard,
            dependencies: makeKeyboardCaptureRefreshDependencies()
        )
        accessibilityGranted = outcome.accessibilityGranted
        inputMonitoringGranted = outcome.inputMonitoringGranted
        capturingKeyboard = outcome.capturingKeyboard
        recordDebug("Privacy status refreshed. ax=\(accessibilityGranted), input=\(inputMonitoringGranted), capturing=\(capturingKeyboard)")
    }

    func openAccessibilitySettings() {
        permissionsController.openAccessibilitySettings()
    }

    func openInputMonitoringSettings() {
        permissionsController.openInputMonitoringSettings()
    }

    func resetPrivacyPermissions() {
        let resetResult = AccessRecoveryRuntimeCoordinator.runResetFlow(
            dependencies: makeAccessRecoveryResetDependencies()
        )
        guard let resetResult else {
            NSLog("Unable to resolve bundle identifier for TCC reset")
            return
        }
        accessActionHint = resetResult.hint
        recordDebug("Privacy permissions reset for bundleID=\(resetResult.bundleID)")
    }

    func runAccessRecoveryWizard() {
        AccessRecoveryRuntimeCoordinator.runWizardFlow(
            dependencies: makeAccessRecoveryWizardDependencies()
        )
        recordDebug("Access recovery wizard started")
    }

    func restartApplication() {
        let plan = AccessRecoveryPlanCoordinator.makePlan()
        appRestartController.restartApplication { [weak self] in
            self?.accessActionHint = plan.restartFailureHint
        }
    }

    func checkForUpdatesInteractive() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            await UpdateCheckRuntimeCoordinator.runIfNeeded(
                isAlreadyInProgress: self.updateCheckInProgress,
                currentVersion: self.appMetadataProvider.currentAppVersion(),
                currentBuild: self.appMetadataProvider.currentAppBuildNumber(),
                dependencies: makeUpdateCheckRuntimeDependencies()
            )
        }
    }

    func playTestSound() {
        soundEngine.startIfNeeded()
        soundEngine.playDown(for: 0, autorepeat: false)
        if playKeyUp {
            soundEngine.playUp(for: 0)
        }
    }

    func startStressTest(duration: TimeInterval = 20) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            await runAutomatedStressTest(duration: duration, includeOutputRouteSimulation: true)
        }
    }

    func runAutomatedStressTest(duration: TimeInterval = 20, includeOutputRouteSimulation: Bool = true) async {
        let decision = StressTestRuntimeCoordinator.begin(
            isInProgress: stressTestInProgress,
            duration: duration,
            includeOutputRouteSimulation: includeOutputRouteSimulation,
            currentProfile: selectedProfile
        )
        guard case let .start(plan) = decision else {
            if case let .skip(debugMessage) = decision {
                recordDebug(debugMessage)
            }
            return
        }

        stressTestInProgress = true
        stressTestProgress = 0
        stressTestStatus = plan.statusText
        recordDebug(plan.startDebugMessage)

        if plan.profilePlan.switchedFromOriginal {
            selectedProfile = plan.profilePlan.effectiveProfile
            if let switchDebugMessage = plan.switchDebugMessage {
                recordDebug(switchDebugMessage)
            }
        }
        start()
        soundEngine.startIfNeeded()

        defer {
            if StressTestRuntimeCoordinator.shouldRestoreOriginalProfile(
                switchedFromOriginal: plan.profilePlan.switchedFromOriginal,
                selectedProfile: selectedProfile,
                originalProfile: plan.originalProfile
            )
            {
                selectedProfile = plan.originalProfile
                recordDebug("Stress test restored profile to \(plan.originalProfile.rawValue)")
            }
            stressTestInProgress = false
            stressTestProgress = 1
        }

        let result = await StressTestService.run(
            duration: plan.effectiveDuration,
            includeOutputRouteSimulation: includeOutputRouteSimulation,
            onProgress: makeStressTestProgressCallback(),
            onDown: makeStressTestDownCallback(),
            onUp: makeStressTestUpCallback(),
            onRouteRebuild: makeStressTestRouteRebuildCallback()
        )

        stressTestStatus = StressTestRuntimeCoordinator.finishStatus(result: result)
        recordDebug(StressTestRuntimeCoordinator.finishDebugMessage(result: result))
    }

    func applyHeadphonesPreset() {
        applySoundSettings(SoundPresetService.headphonesPreset())
    }

    func applySpeakersPreset() {
        applySoundSettings(SoundPresetService.speakersPreset())
    }

    private func applyProfileSoundPreset(for profile: SoundProfile) {
        let decision = ProfilePresetCoordinator.decide(for: profile)
        if let settings = decision.settings {
            applySoundSettings(settings)
        }
        profilePresetLastApplied = decision.label
    }

    private func applySoundSettings(_ settings: SoundSettings) {
        applySoundStatePatch(SoundStatePatchMapper.soundSettingsPatch(from: settings))
    }

    private func applyCompensationSettings(_ settings: CompensationSettings) {
        dynamicCompensationEnabled = settings.dynamicCompensationEnabled
        levelMacLow = settings.levelMacLow
        levelKbdLow = settings.levelKbdLow
        levelMacLowMid = settings.levelMacLowMid
        levelKbdLowMid = settings.levelKbdLowMid
        levelMacMid = settings.levelMacMid
        levelKbdMid = settings.levelKbdMid
        levelMacHighMid = settings.levelMacHighMid
        levelKbdHighMid = settings.levelKbdHighMid
        levelMacHigh = settings.levelMacHigh
        levelKbdHigh = settings.levelKbdHigh
        strictVolumeNormalizationEnabled = settings.strictVolumeNormalizationEnabled
    }

    func playABComparison() {
        guard !isABPlaying else { return }
        isABPlaying = true

        let restoreState = ABComparisonRuntimeCoordinator.capture(makeABComparisonStateSource())
        let baseline = ABComparisonRuntimeCoordinator.baselineBurstState

        Task { @MainActor [weak self] in
            guard let self else { return }

            await ABComparisonScenarioCoordinator.run(
                feature: self.abFeature,
                dependencies: makeABComparisonScenarioDependencies(baseline: baseline)
            )

            try? await Task.sleep(nanoseconds: 120_000_000)
            self.restoreABComparisonState(restoreState)
        }
    }

    private func playABStressBurst() async {
        soundEngine.startIfNeeded()
        await ABStressBurstCoordinator.run(
            playKeyUp: playKeyUp,
            dependencies: ABStressBurstDependencies(
                playDown: { [weak self] key in
                    self?.soundEngine.playDown(for: key, autorepeat: false)
                },
                playUp: { [weak self] key in
                    self?.soundEngine.playUp(for: key)
                },
                sleep: { nanoseconds in
                    try? await Task.sleep(nanoseconds: nanoseconds)
                }
            )
        )
    }

    func exportSettings() {
        ProfileSettingsRuntimeCoordinator.runExport(
            source: ProfileSettingsExportSource(
                selectedProfile: selectedProfile,
                volume: volume,
                variation: variation,
                playKeyUp: playKeyUp,
                pressLevel: pressLevel,
                releaseLevel: releaseLevel,
                spaceLevel: spaceLevel
            ),
            dependencies: makeProfileSettingsRuntimeDependencies()
        )
    }

    func importSettings() {
        ProfileSettingsRuntimeCoordinator.runImport(
            fallbackProfile: selectedProfile,
            dependencies: makeProfileSettingsRuntimeDependencies()
        )
    }

    private func applyImportedProfileSettings(_ state: ProfileSettingsState) {
        applySoundStatePatch(SoundStatePatchMapper.importedProfilePatch(from: state))
    }

    private func makeProfileSettingsRuntimeDependencies() -> ProfileSettingsRuntimeDependencies {
        ProfileSettingsRuntimeDependencies(
            exportSettings: { [weak self] state in
                self?.profileSettingsTransferCoordinator.exportSettings(from: state) ?? .cancelled
            },
            importSettings: { [weak self] fallback in
                self?.profileSettingsTransferCoordinator.importSettings(fallbackProfile: fallback) ?? (.cancelled, nil)
            },
            applyImportedSettings: { [weak self] state in
                self?.applyImportedProfileSettings(state)
            },
            recordDebug: { [weak self] message in
                self?.recordDebug(message)
            }
        )
    }

    func clearDebugLog() {
        debugLogService.clear()
        persistentDebugLogService.clearLogFile()
        debugLogPreview = "Лог очищен."
        recordDebug("Debug log cleared")
    }

    func exportDebugLog() {
        let source = makeDiagnosticsExportRuntimeSource()
        let result = DiagnosticsExportRuntimeCoordinator.export(
            source: source,
            diagnosticsSnapshotFactory: diagnosticsSnapshotFactory,
            debugLogService: debugLogService,
            debugLogExportCoordinator: debugLogExportCoordinator
        )
        RuntimeResultLoggingCoordinator.handleDebugLogExportResult(result) { [weak self] message in
            self?.recordDebug(message)
        }
    }

    private func updateLaunchAtLogin() {
        do {
            try launchAtLoginController.setEnabled(launchAtLogin)
        } catch {
            NSLog("Failed to update launch at login: \(error)")
        }
    }

    private func updateSystemVolumeMonitoringState() {
        // Keep a lightweight monitor always to detect output-device changes.
        let targetInterval: TimeInterval = (dynamicCompensationEnabled || strictVolumeNormalizationEnabled) ? 0.6 : 1.4
        systemAudioMonitor.ensureInterval(targetInterval) { [weak self] payload in
            self?.handleSystemAudioPoll(payload)
        }
    }

    private func handleSystemAudioPoll(_ payload: SystemAudioPollPayload) {
        let currentState = makeSystemAudioPollState()
        let outcome = SystemAudioPollRuntimeCoordinator.handle(
            payload: payload,
            state: currentState,
            dependencies: makeSystemAudioPollRuntimeDependencies()
        )

        applySystemAudioPollState(outcome.state)

        if outcome.didRebuildForAvailabilityChange {
            recordDebug("Output stream availability changed. Rebuilt audio graph")
        }
    }

    private func handleOutputDeviceTransition(result: SystemAudioPollResult) {
        let outcome = OutputDeviceTransitionRuntimeCoordinator.handle(
            result: result,
            perDeviceSoundProfileEnabled: perDeviceSoundProfileEnabled,
            hasPersistedPrimarySettings: hasPersistedPrimarySettings,
            dependencies: makeOutputDeviceTransitionRuntimeDependencies()
        )
        currentOutputDeviceBoost = outcome.currentOutputDeviceBoost
        if let statusLabel = outcome.statusLabel {
            autoOutputPresetLastApplied = statusLabel
        }
        let deviceUID = result.deviceUID
        let deviceName = result.deviceName
        recordDebug("Output device changed: \(deviceName) [uid=\(deviceUID.isEmpty ? "n/a" : deviceUID)]")
    }

    private func startFailSafeMonitoring() {
        failSafeTimer?.invalidate()
        failSafeTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.runFailSafeTick()
            }
        }
    }

    private func runFailSafeTick() {
        let outcome = FailSafeRuntimeCoordinator.run(
            input: FailSafeRuntimeInput(
                now: CFAbsoluteTimeGetCurrent(),
                resetThreshold: 6.0,
                isEnabled: isEnabled,
                currentlyCapturingKeyboard: capturingKeyboard,
                accessibilityGranted: accessibilityGranted,
                inputMonitoringGranted: inputMonitoringGranted
            ),
            dependencies: makeFailSafeRuntimeDependencies()
        )

        if outcome.didResetStuckPoll {
            recordDebug("Fail-safe: reset stuck system-volume poll (>6.0s)")
        }
        if let restarted = outcome.recoveredKeyboardCapture {
            capturingKeyboard = restarted
            if restarted {
                recordDebug("Fail-safe: keyboard capture auto-restarted")
            }
        }
    }

    private func updateDynamicCompensation() {
        let gain = DynamicCompensationCoordinator.resolveGain(makeDynamicCompensationInput())
        let clamped = Float(gain).clamped(to: 0.20 ... 6.0)
        soundEngine.dynamicCompensationGain = clamped
        let next = Double(clamped)
        if abs(liveDynamicGain - next) > 0.005 {
            liveDynamicGain = next
        }
    }

    private func curveGainAt(systemVolume: Double) -> Double {
        CompensationCurveCoordinator.curveGain(
            systemVolume: systemVolume,
            macLow: levelMacLow,
            kbdLow: levelKbdLow,
            macLowMid: levelMacLowMid,
            kbdLowMid: levelKbdLowMid,
            macMid: levelMacMid,
            kbdMid: levelKbdMid,
            macHighMid: levelMacHighMid,
            kbdHighMid: levelKbdHighMid,
            macHigh: levelMacHigh,
            kbdHigh: levelKbdHigh
        )
    }

    private func strictCurveGain(systemVolume: Double) -> Double {
        CompensationCurveCoordinator.strictCurveGain(
            systemVolume: systemVolume,
            targetAt100: autoNormalizeTargetAt100,
            macLow: levelMacLow,
            kbdLow: levelKbdLow,
            macLowMid: levelMacLowMid,
            kbdLowMid: levelKbdLowMid,
            macMid: levelMacMid,
            kbdMid: levelKbdMid,
            macHighMid: levelMacHighMid,
            kbdHighMid: levelKbdHighMid,
            macHigh: levelMacHigh,
            kbdHigh: levelKbdHigh
        )
    }

    private func applyLayerThresholds() {
        let slam = layerThresholdSlam.clamped(to: 0.010 ... 0.120)
        let hard = max(slam + 0.006, layerThresholdHard).clamped(to: 0.025 ... 0.180)
        let medium = max(hard + 0.006, layerThresholdMedium).clamped(to: 0.040 ... 0.260)
        soundEngine.setVelocityThresholds(slam: slam, hard: hard, medium: medium)
    }

    private func applyAutoOutputPresetIfNeeded(deviceUID: String, deviceName: String) {
        let decision = AutoOutputPresetCoordinator.decide(
            autoOutputPresetEnabled: autoOutputPresetEnabled,
            deviceUID: deviceUID,
            lastAutoPresetDeviceUID: lastAutoPresetDeviceUID,
            deviceName: deviceName
        )
        guard decision.shouldApply else { return }

        if let nextUID = decision.nextLastAutoPresetDeviceUID {
            lastAutoPresetDeviceUID = nextUID
        }

        switch decision.presetKind {
        case .headphones:
            applyHeadphonesPreset()
            autoOutputPresetLastApplied = "Наушники"
        case .speakers:
            applySpeakersPreset()
            autoOutputPresetLastApplied = "Динамики"
        case .none:
            return
        }
        recordDebug("Auto output preset applied: \(autoOutputPresetLastApplied) for \(deviceName)")
    }

    func autoInverseGainPreview(systemVolumePercent: Double) -> Double {
        let normalized = (systemVolumePercent / 100.0).clamped(to: 0.0 ... 1.0)
        if strictVolumeNormalizationEnabled && levelTuningMode == .simple {
            return AudioCompensationMath.autoInverseGain(
                systemVolumeScalar: normalized,
                targetAt100: autoNormalizeTargetAt100
            )
        }
        if strictVolumeNormalizationEnabled {
            return strictCurveGain(systemVolume: normalized)
        }
        return curveGainAt(systemVolume: normalized)
    }

    private func trackTypingHit() {
        let snapshot = typingMetricsService.registerHit()
        applyTypingSnapshot(snapshot)
        updateTypingAdaptation()
    }

    private func updateTypingDecayMonitoringState() {
        typingMetricsService.setDecayMonitoringEnabled(
            typingAdaptiveEnabled && !strictVolumeNormalizationEnabled
        ) { [weak self] snapshot in
            guard let self else { return }
            self.applyTypingSnapshot(snapshot)
            self.updateTypingAdaptation()
        }
    }

    private func applyTypingSnapshot(_ snapshot: TypingMetricsSnapshot) {
        if abs(typingCPS - snapshot.cps) > 0.03 {
            typingCPS = snapshot.cps
        }
        if abs(typingWPM - snapshot.wpm) > 0.4 {
            typingWPM = snapshot.wpm
        }
    }

    private func updateTypingAdaptation() {
        let gain = TypingAdaptationCoordinator.resolveGain(makeTypingAdaptationInput())
        soundEngine.typingSpeedGain = Float(gain)
        if abs(liveTypingGain - gain) > 0.005 {
            liveTypingGain = gain
        }
    }

    private func snapshotSummaryLines() -> [String] {
        let source = makeRuntimeSettingsSummarySource()
        return RuntimeSettingsSummaryBuilder.build(RuntimeSettingsSummaryMapper.map(source))
    }

    private func makeRuntimeSettingsSummarySource() -> RuntimeSettingsSummarySource {
        RuntimeSettingsSummarySource(
            selectedProfileRawValue: selectedProfile.rawValue,
            volume: volume,
            variation: variation,
            pitchVariation: pitchVariation,
            pressLevel: pressLevel,
            releaseLevel: releaseLevel,
            spaceLevel: spaceLevel,
            stackModeEnabled: stackModeEnabled,
            limiterEnabled: limiterEnabled,
            limiterDrive: limiterDrive,
            minInterKeyGapMs: minInterKeyGapMs,
            releaseDuckingStrength: releaseDuckingStrength,
            releaseDuckingWindowMs: releaseDuckingWindowMs,
            releaseTailTightness: releaseTailTightness,
            levelMacLow: levelMacLow,
            levelKbdLow: levelKbdLow,
            levelMacLowMid: levelMacLowMid,
            levelKbdLowMid: levelKbdLowMid,
            levelMacMid: levelMacMid,
            levelKbdMid: levelKbdMid,
            levelMacHighMid: levelMacHighMid,
            levelKbdHighMid: levelKbdHighMid,
            levelMacHigh: levelMacHigh,
            levelKbdHigh: levelKbdHigh,
            dynamicCompensationEnabled: dynamicCompensationEnabled,
            strictVolumeNormalizationEnabled: strictVolumeNormalizationEnabled,
            typingAdaptiveEnabled: typingAdaptiveEnabled,
            launchAtLogin: launchAtLogin,
            autoOutputPresetEnabled: autoOutputPresetEnabled,
            perDeviceSoundProfileEnabled: perDeviceSoundProfileEnabled,
            appearanceModeRawValue: appearanceMode.rawValue
        )
    }

    private func makeDynamicCompensationInput() -> DynamicCompensationInput {
        DynamicCompensationInput(
            strictVolumeNormalizationEnabled: strictVolumeNormalizationEnabled,
            levelTuningMode: levelTuningMode,
            lastSystemVolume: lastSystemVolume,
            autoNormalizeTargetAt100: autoNormalizeTargetAt100,
            levelMacLow: levelMacLow,
            levelKbdLow: levelKbdLow,
            levelMacLowMid: levelMacLowMid,
            levelKbdLowMid: levelKbdLowMid,
            levelMacMid: levelMacMid,
            levelKbdMid: levelKbdMid,
            levelMacHighMid: levelMacHighMid,
            levelKbdHighMid: levelKbdHighMid,
            levelMacHigh: levelMacHigh,
            levelKbdHigh: levelKbdHigh,
            dynamicCompensationEnabled: dynamicCompensationEnabled,
            compensationStrength: compensationStrength,
            currentOutputDeviceBoost: currentOutputDeviceBoost
        )
    }

    private func makeTypingAdaptationInput() -> TypingAdaptationInput {
        TypingAdaptationInput(
            strictVolumeNormalizationEnabled: strictVolumeNormalizationEnabled,
            typingAdaptiveEnabled: typingAdaptiveEnabled,
            typingCPS: typingCPS,
            personalBaselineCPS: typingMetricsService.personalBaselineCPS
        )
    }

    private func recordDebug(_ message: String) {
        let timestamp = DiagnosticsTimestampProvider.debugTimestamp()
        let line = debugLogService.append(message: message, timestamp: timestamp)
        persistentDebugLogService.append(line)
        debugLogPreview = debugLogService.preview(maxLines: 180)
        NSLog("KlacDebug: \(message)")
    }

    private func saveCurrentDeviceBoost() {
        perDeviceSnapshotRuntime.persistCurrentDeviceState(
            perDeviceSoundProfileEnabled: perDeviceSoundProfileEnabled,
            deviceUID: currentOutputDeviceUID,
            currentOutputDeviceBoost: currentOutputDeviceBoost,
            source: currentDeviceStateSource()
        )
    }

    private func persistPerDeviceSnapshotIfNeeded() {
        persistSnapshot(for: currentOutputDeviceUID)
    }

    private func persistCurrentProfileSnapshotIfNeeded() {
        guard !isRestoringPersistedState, !isApplyingProfileSnapshot else { return }
        persistProfileSnapshot(for: selectedProfile)
    }

    private func persistProfileSnapshot(for profile: SoundProfile) {
        perProfileSoundSnapshots[profile.rawValue] = currentProfileSoundSnapshot()
        settingsStore.encode(perProfileSoundSnapshots, forKey: SettingsKeys.perProfileSoundSnapshots)
    }

    private func currentProfileSoundSnapshot() -> ProfileSoundSnapshot {
        ProfileSoundSnapshot(
            playKeyUp: playKeyUp,
            volume: volume,
            variation: variation,
            pitchVariation: pitchVariation,
            pressLevel: pressLevel,
            releaseLevel: releaseLevel,
            spaceLevel: spaceLevel,
            stackModeEnabled: stackModeEnabled,
            stackDensity: stackDensity,
            layerThresholdSlam: layerThresholdSlam,
            layerThresholdHard: layerThresholdHard,
            layerThresholdMedium: layerThresholdMedium,
            limiterEnabled: limiterEnabled,
            limiterDrive: limiterDrive,
            minInterKeyGapMs: minInterKeyGapMs,
            releaseDuckingStrength: releaseDuckingStrength,
            releaseDuckingWindowMs: releaseDuckingWindowMs,
            releaseTailTightness: releaseTailTightness
        )
    }

    private func restoreProfileSnapshot(for profile: SoundProfile) -> Bool {
        guard let snapshot = perProfileSoundSnapshots[profile.rawValue] else { return false }
        isApplyingProfileSnapshot = true
        defer { isApplyingProfileSnapshot = false }
        applyProfileSoundSnapshot(snapshot)
        return true
    }

    private func applyProfileSoundSnapshot(_ snapshot: ProfileSoundSnapshot) {
        playKeyUp = snapshot.playKeyUp
        volume = snapshot.volume.clamped(to: 0.0 ... 1.0)
        variation = snapshot.variation.clamped(to: 0.0 ... 1.0)
        pitchVariation = snapshot.pitchVariation.clamped(to: 0.0 ... 0.6)
        pressLevel = snapshot.pressLevel.clamped(to: 0.2 ... 1.6)
        releaseLevel = snapshot.releaseLevel.clamped(to: 0.1 ... 1.4)
        spaceLevel = snapshot.spaceLevel.clamped(to: 0.2 ... 1.8)
        stackModeEnabled = snapshot.stackModeEnabled
        stackDensity = snapshot.stackDensity.clamped(to: 0.0 ... 1.0)
        layerThresholdSlam = snapshot.layerThresholdSlam.clamped(to: 0.010 ... 0.120)
        layerThresholdHard = snapshot.layerThresholdHard.clamped(to: 0.025 ... 0.180)
        layerThresholdMedium = snapshot.layerThresholdMedium.clamped(to: 0.040 ... 0.260)
        limiterEnabled = snapshot.limiterEnabled
        limiterDrive = snapshot.limiterDrive.clamped(to: 0.6 ... 2.0)
        minInterKeyGapMs = snapshot.minInterKeyGapMs.clamped(to: 0 ... 45)
        releaseDuckingStrength = snapshot.releaseDuckingStrength.clamped(to: 0 ... 1)
        releaseDuckingWindowMs = snapshot.releaseDuckingWindowMs.clamped(to: 20 ... 180)
        releaseTailTightness = snapshot.releaseTailTightness.clamped(to: 0 ... 1)
    }

    private func currentDeviceStateSource() -> DeviceSoundStateSource {
        DeviceSoundStateSource(
            volume: volume,
            variation: variation,
            pitchVariation: pitchVariation,
            pressLevel: pressLevel,
            releaseLevel: releaseLevel,
            spaceLevel: spaceLevel,
            levelMacLowMid: levelMacLowMid,
            levelKbdLowMid: levelKbdLowMid,
            levelMacHighMid: levelMacHighMid,
            levelKbdHighMid: levelKbdHighMid,
            stackModeEnabled: stackModeEnabled,
            limiterEnabled: limiterEnabled,
            limiterDrive: limiterDrive,
            minInterKeyGapMs: minInterKeyGapMs,
            releaseDuckingStrength: releaseDuckingStrength,
            releaseDuckingWindowMs: releaseDuckingWindowMs,
            releaseTailTightness: releaseTailTightness,
            currentOutputDeviceBoost: currentOutputDeviceBoost
        )
    }

    private func persistSnapshot(for deviceUID: String) {
        perDeviceSnapshotRuntime.persistSnapshotIfNeeded(
            perDeviceSoundProfileEnabled: perDeviceSoundProfileEnabled,
            deviceUID: deviceUID,
            source: currentDeviceStateSource()
        )
    }

    private func restoreSnapshot(for deviceUID: String) -> Bool {
        guard let patch = perDeviceSnapshotRuntime.restoreSnapshotPatchIfAvailable(deviceUID: deviceUID) else {
            return false
        }
        applySoundStatePatch(patch)
        return true
    }

    private func applySoundStatePatch(_ patch: SoundStatePatch) {
        if let selectedProfile = patch.selectedProfile { self.selectedProfile = selectedProfile }
        if let volume = patch.volume { self.volume = volume }
        if let variation = patch.variation { self.variation = variation }
        if let playKeyUp = patch.playKeyUp { self.playKeyUp = playKeyUp }
        if let pitchVariation = patch.pitchVariation { self.pitchVariation = pitchVariation }
        if let pressLevel = patch.pressLevel { self.pressLevel = pressLevel }
        if let releaseLevel = patch.releaseLevel { self.releaseLevel = releaseLevel }
        if let spaceLevel = patch.spaceLevel { self.spaceLevel = spaceLevel }
        if let levelMacLowMid = patch.levelMacLowMid { self.levelMacLowMid = levelMacLowMid }
        if let levelKbdLowMid = patch.levelKbdLowMid { self.levelKbdLowMid = levelKbdLowMid }
        if let levelMacHighMid = patch.levelMacHighMid { self.levelMacHighMid = levelMacHighMid }
        if let levelKbdHighMid = patch.levelKbdHighMid { self.levelKbdHighMid = levelKbdHighMid }
        if let stackModeEnabled = patch.stackModeEnabled { self.stackModeEnabled = stackModeEnabled }
        if let limiterEnabled = patch.limiterEnabled { self.limiterEnabled = limiterEnabled }
        if let limiterDrive = patch.limiterDrive { self.limiterDrive = limiterDrive }
        if let minInterKeyGapMs = patch.minInterKeyGapMs { self.minInterKeyGapMs = minInterKeyGapMs }
        if let releaseDuckingStrength = patch.releaseDuckingStrength { self.releaseDuckingStrength = releaseDuckingStrength }
        if let releaseDuckingWindowMs = patch.releaseDuckingWindowMs { self.releaseDuckingWindowMs = releaseDuckingWindowMs }
        if let releaseTailTightness = patch.releaseTailTightness { self.releaseTailTightness = releaseTailTightness }
        if let currentOutputDeviceBoost = patch.currentOutputDeviceBoost { self.currentOutputDeviceBoost = currentOutputDeviceBoost }
    }

    private func makeSystemAudioPollState() -> SystemAudioPollState {
        SystemAudioPollState(
            detectedSystemVolumeAvailable: detectedSystemVolumeAvailable,
            detectedSystemVolumePercent: detectedSystemVolumePercent,
            lastSystemVolume: lastSystemVolume,
            lastOutputDeviceID: lastOutputDeviceID,
            currentOutputDeviceUID: currentOutputDeviceUID,
            currentOutputDeviceName: currentOutputDeviceName,
            initialOutputDeviceResolved: initialOutputDeviceResolved
        )
    }

    private func applySystemAudioPollState(_ state: SystemAudioPollState) {
        detectedSystemVolumeAvailable = state.detectedSystemVolumeAvailable
        detectedSystemVolumePercent = state.detectedSystemVolumePercent
        lastSystemVolume = state.lastSystemVolume
        lastOutputDeviceID = state.lastOutputDeviceID
        currentOutputDeviceUID = state.currentOutputDeviceUID
        currentOutputDeviceName = state.currentOutputDeviceName
        initialOutputDeviceResolved = state.initialOutputDeviceResolved
    }

    private func makeVelocityLayerChangedCallback() -> (String) -> Void {
        { [weak self] layer in
            Task { @MainActor [weak self] in
                self?.liveVelocityLayer = layer
            }
        }
    }

    private func makeManifestValidationCallback() -> (String, [String]) -> Void {
        { [weak self] summary, issues in
            Task { @MainActor [weak self] in
                self?.manifestValidationSummary = summary
                self?.manifestValidationIssues = issues
            }
        }
    }

    private func makeAudioDiagnosticCallback() -> (String) -> Void {
        { [weak self] message in
            Task { @MainActor [weak self] in
                self?.recordDebug("Audio: \(message)")
            }
        }
    }

    private func makeKeyboardInputRuntimeDependencies() -> KeyboardInputRuntimeDependencies {
        KeyboardInputRuntimeDependencies(
            trackTypingHit: { [weak self] in
                self?.trackTypingHit()
            },
            playDown: { [weak self] keyCode, isAutorepeat in
                self?.soundEngine.playDown(for: keyCode, autorepeat: isAutorepeat)
            },
            playUp: { [weak self] keyCode in
                self?.soundEngine.playUp(for: keyCode)
            }
        )
    }

    private func makeStressTestProgressCallback() -> (Double) -> Void {
        { [weak self] progress in
            self?.stressTestProgress = progress
        }
    }

    private func makeStressTestDownCallback() -> (Int, Bool) -> Void {
        { [weak self] keyCode, autorepeat in
            self?.soundEngine.playDown(for: keyCode, autorepeat: autorepeat)
        }
    }

    private func makeStressTestUpCallback() -> (Int) -> Void {
        { [weak self] keyCode in
            self?.soundEngine.playUp(for: keyCode)
        }
    }

    private func makeStressTestRouteRebuildCallback() -> () -> Void {
        { [weak self] in
            self?.soundEngine.handleOutputDeviceChanged()
        }
    }

    private func makeABComparisonStateSource() -> ABComparisonStateSource {
        ABComparisonStateSource(
            dynamicCompensationEnabled: dynamicCompensationEnabled,
            typingAdaptiveEnabled: typingAdaptiveEnabled,
            limiterEnabled: limiterEnabled,
            compensationStrength: compensationStrength,
            volume: volume,
            pressLevel: pressLevel,
            releaseLevel: releaseLevel,
            spaceLevel: spaceLevel,
            lastSystemVolume: lastSystemVolume
        )
    }

    private func makeABComparisonScenarioDependencies(
        baseline: ABComparisonBaselineState
    ) -> ABComparisonScenarioDependencies {
        ABComparisonScenarioDependencies(
            applyBaselineForBurst: { [weak self] in
                guard let self else { return }
                self.volume = baseline.volume
                self.pressLevel = baseline.pressLevel
                self.releaseLevel = baseline.releaseLevel
                self.spaceLevel = baseline.spaceLevel
                self.compensationStrength = baseline.compensationStrength
                self.lastSystemVolume = baseline.lastSystemVolume
            },
            setDynamicCompensationEnabled: { [weak self] value in
                self?.dynamicCompensationEnabled = value
            },
            setLimiterEnabled: { [weak self] value in
                self?.limiterEnabled = value
            },
            setTypingAdaptiveEnabled: { [weak self] value in
                self?.typingAdaptiveEnabled = value
            },
            updateDynamicCompensation: { [weak self] in
                self?.updateDynamicCompensation()
            },
            playStressBurst: { [weak self] in
                await self?.playABStressBurst()
            },
            playTestSound: { [weak self] in
                self?.playTestSound()
            },
            sleep: { nanoseconds in
                try? await Task.sleep(nanoseconds: nanoseconds)
            }
        )
    }

    private func restoreABComparisonState(_ state: ABComparisonRestoreState) {
        dynamicCompensationEnabled = state.dynamicCompensationEnabled
        typingAdaptiveEnabled = state.typingAdaptiveEnabled
        limiterEnabled = state.limiterEnabled
        compensationStrength = state.compensationStrength
        volume = state.volume
        pressLevel = state.pressLevel
        releaseLevel = state.releaseLevel
        spaceLevel = state.spaceLevel
        lastSystemVolume = state.lastSystemVolume
        updateDynamicCompensation()
        isABPlaying = false
    }

    private func makeDiagnosticsExportRuntimeSource() -> DiagnosticsExportRuntimeSource {
        DiagnosticsExportRuntimeSource(
            outputDeviceName: currentOutputDeviceName,
            outputUID: currentOutputDeviceUID,
            accessibilityGranted: accessibilityGranted,
            inputMonitoringGranted: inputMonitoringGranted,
            capturingKeyboard: capturingKeyboard,
            systemVolumeAvailable: detectedSystemVolumeAvailable,
            systemVolumePercent: detectedSystemVolumePercent,
            runtimeSettings: snapshotSummaryLines(),
            stressTestStatus: stressTestStatus
        )
    }

    private func makeAccessRecoveryResetDependencies() -> AccessRecoveryResetDependencies {
        AccessRecoveryResetDependencies(
            resolveBundleID: { [weak self] in
                self?.appMetadataProvider.resolveBundleIdentifier()
            },
            resetTCC: { [weak self] service, bundleID in
                self?.permissionsController.resetTCC(service: service, bundleID: bundleID)
            },
            openAccessibilitySettings: { [weak self] in
                self?.openAccessibilitySettings()
            },
            openInputMonitoringSettings: { [weak self] in
                self?.openInputMonitoringSettings()
            },
            schedulePostResetRefresh: { [weak self] work in
                self?.accessRecoveryCoordinator.schedulePostResetRefresh(work)
            },
            refreshStatus: { [weak self] in
                self?.refreshAccessibilityStatus(promptIfNeeded: false)
            }
        )
    }

    private func makeAccessRecoveryWizardDependencies() -> AccessRecoveryWizardDependencies {
        AccessRecoveryWizardDependencies(
            runResetFlow: { [weak self] in
                self?.resetPrivacyPermissions()
            },
            setHint: { [weak self] hint in
                self?.accessActionHint = hint
            },
            scheduleWizard: { [weak self] open, setHint, restart in
                self?.accessRecoveryCoordinator.scheduleWizard(
                    openSettings: open,
                    setHint: setHint,
                    restart: restart
                )
            },
            openSettings: { [weak self] in
                self?.openAccessibilitySettings()
                self?.openInputMonitoringSettings()
            },
            restartApplication: { [weak self] in
                self?.restartApplication()
            }
        )
    }

    private func makeOutputDeviceTransitionRuntimeDependencies() -> OutputDeviceTransitionRuntimeDependencies {
        OutputDeviceTransitionRuntimeDependencies(
            saveSnapshot: { [weak self] uid in
                self?.persistSnapshot(for: uid)
            },
            loadBoost: { [weak self] uid in
                guard let self else { return 1.0 }
                return self.perDeviceSnapshotRuntime.loadBoost(deviceUID: uid)
            },
            rebuildAudioGraph: { [weak self] in
                self?.soundEngine.handleOutputDeviceChanged()
            },
            restoreSnapshot: { [weak self] uid in
                self?.restoreSnapshot(for: uid) ?? false
            },
            applyAutoPreset: { [weak self] uid, name in
                self?.applyAutoOutputPresetIfNeeded(deviceUID: uid, deviceName: name)
            }
        )
    }

    private func makeKeyboardCaptureStartDependencies() -> KeyboardCaptureStartDependencies {
        KeyboardCaptureStartDependencies(
            refreshStatus: { [weak self] in
                self?.permissionsController.refreshStatus(promptIfNeeded: false) ?? PermissionsStatus(
                    accessibilityGranted: false,
                    inputMonitoringGranted: false
                )
            },
            startAudio: { [weak self] in
                self?.soundEngine.startIfNeeded()
            },
            startInputCapture: { [weak self] in
                self?.inputMonitor.start() ?? false
            }
        )
    }

    private func makeKeyboardCaptureRefreshDependencies() -> KeyboardCaptureRefreshDependencies {
        KeyboardCaptureRefreshDependencies(
            refreshStatus: { [weak self] promptIfNeeded in
                self?.permissionsController.refreshStatus(promptIfNeeded: promptIfNeeded) ?? PermissionsStatus(
                    accessibilityGranted: false,
                    inputMonitoringGranted: false
                )
            },
            startAudio: { [weak self] in
                self?.soundEngine.startIfNeeded()
            },
            startInputCapture: { [weak self] in
                self?.inputMonitor.start() ?? false
            }
        )
    }

    private func makeKeyboardCaptureStopDependencies() -> KeyboardCaptureStopDependencies {
        KeyboardCaptureStopDependencies(
            stopInputCapture: { [weak self] in
                self?.inputMonitor.stop()
            },
            stopAudio: { [weak self] in
                self?.soundEngine.stop()
            }
        )
    }

    private func makeUpdateCheckRuntimeDependencies() -> UpdateCheckRuntimeDependencies {
        UpdateCheckRuntimeDependencies(
            setInProgress: { [weak self] value in
                self?.updateCheckInProgress = value
            },
            setStatusText: { [weak self] value in
                self?.updateStatusText = value
            },
            recordDebug: { [weak self] message in
                self?.recordDebug(message)
            },
            runFlow: { [weak self] version, build in
                await self?.updateCheckFlowCoordinator.run(currentVersion: version, currentBuild: build)
                    ?? UpdateCheckPresentation(statusText: "Ошибка проверки обновлений", debugMessage: "Update flow unavailable", action: nil)
            },
            executeAction: { [weak self] action in
                guard let self else { return }
                UpdateCheckActionExecutor.execute(action, alertPresenter: self.alertPresenter, urlOpener: self.urlOpener)
            }
        )
    }

    private func makeSystemAudioPollRuntimeDependencies() -> SystemAudioPollRuntimeDependencies {
        SystemAudioPollRuntimeDependencies(
            handleOutputDeviceTransition: { [weak self] result in
                self?.handleOutputDeviceTransition(result: result)
            },
            rebuildAudioGraphAfterAvailabilityChange: { [weak self] in
                self?.soundEngine.handleOutputDeviceChanged()
            },
            updateDynamicCompensation: { [weak self] in
                self?.updateDynamicCompensation()
            }
        )
    }

    private func makeFailSafeRuntimeDependencies() -> FailSafeRuntimeDependencies {
        FailSafeRuntimeDependencies(
            resetStuckPollIfNeeded: { [weak self] now, threshold in
                self?.systemAudioMonitor.resetStuckPollIfNeeded(now: now, threshold: threshold) ?? false
            },
            recoverKeyboardCaptureIfNeeded: { [weak self] isEnabled, accessibilityGranted, inputMonitoringGranted, currentlyCapturingKeyboard in
                self?.inputMonitor.recoverIfNeeded(
                    isEnabled: isEnabled,
                    accessibilityGranted: accessibilityGranted,
                    inputMonitoringGranted: inputMonitoringGranted,
                    currentlyCapturing: currentlyCapturingKeyboard
                ) ?? currentlyCapturingKeyboard
            },
            runAudioEngineFailSafe: { [weak self] in
                self?.soundEngine.runFailSafeTick()
            }
        )
    }

}
