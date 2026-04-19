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
        didSet { syncSettingFlag(playKeyUp, key: SettingsKeys.playKeyUp) }
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
        didSet { syncSelectedProfile(selectedProfile) }
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
    private var perDeviceSnapshotService: PerDeviceSnapshotService
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
        perDeviceSnapshotService = PerDeviceSnapshotService(
            settingsStore: self.settingsStore,
            snapshots: persistedState.perDeviceSoundSnapshots,
            boosts: persistedState.outputDeviceBoosts
        )
        hasPersistedPrimarySettings = persistedState.hasPrimaryPersistedSettings
        restorePersistedState(persistedState)
        configureSoundEngine()
        startRuntimeServices()
        configureEventTap()
        updateLaunchAtLogin()
        registerTerminationObserver()
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
        selectedProfile = plan.selectedProfile
        playKeyUp = plan.playKeyUp
        autoProfileTuningEnabled = plan.autoProfileTuningEnabled
        applySoundSettings(plan.soundSettings)
        stackDensity = plan.stackDensity
        layerThresholdSlam = plan.layerThresholdSlam
        layerThresholdHard = plan.layerThresholdHard
        layerThresholdMedium = plan.layerThresholdMedium
    }

    private func applyPersistedCompensationState(_ plan: PersistedCompensationStatePlan) {
        dynamicCompensationEnabled = plan.dynamicCompensationEnabled
        compensationStrength = plan.compensationStrength
        levelMacLow = plan.levelMacLow
        levelKbdLow = plan.levelKbdLow
        levelMacLowMid = plan.levelMacLowMid
        levelKbdLowMid = plan.levelKbdLowMid
        levelMacMid = plan.levelMacMid
        levelKbdMid = plan.levelKbdMid
        levelMacHighMid = plan.levelMacHighMid
        levelKbdHighMid = plan.levelKbdHighMid
        levelMacHigh = plan.levelMacHigh
        levelKbdHigh = plan.levelKbdHigh
        strictVolumeNormalizationEnabled = plan.strictVolumeNormalizationEnabled
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
        soundEngine.onVelocityLayerChanged = { [weak self] layer in
            Task { @MainActor [weak self] in
                self?.liveVelocityLayer = layer
            }
        }
        soundEngine.onManifestValidation = { [weak self] summary, issues in
            Task { @MainActor [weak self] in
                self?.manifestValidationSummary = summary
                self?.manifestValidationIssues = issues
            }
        }
        soundEngine.onDiagnostic = { [weak self] message in
            Task { @MainActor [weak self] in
                self?.recordDebug("Audio: \(message)")
            }
        }
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
            guard let self else { return }
            let plan = KeyboardInputEventCoordinator.makePlan(KeyboardInputEventContext(
                isEnabled: self.isEnabled,
                playKeyUp: self.playKeyUp,
                type: type,
                keyCode: keyCode,
                isAutorepeat: isAutorepeat
            ))
            if plan.shouldTrackTyping {
                self.trackTypingHit()
            }
            if plan.shouldPlayDown {
                self.soundEngine.playDown(for: keyCode, autorepeat: isAutorepeat)
            }
            if plan.shouldPlayUp {
                self.soundEngine.playUp(for: keyCode)
            }
        }
    }

    private func registerTerminationObserver() {
        appWillTerminateObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.persistPerDeviceSnapshotIfNeeded()
            }
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
    }

    private func syncSoundFlag(_ value: Bool, key: String, apply: (Bool) -> Void) {
        settingsStore.set(value, forKey: key)
        apply(value)
        persistPerDeviceSnapshotIfNeeded()
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

    private func syncSelectedProfile(_ profile: SoundProfile) {
        soundEngine.setProfile(profile)
        if !isRestoringPersistedState, autoProfileTuningEnabled {
            applyProfileSoundPreset(for: profile)
        }
        if !isRestoringPersistedState {
            settingsStore.set(profile.rawValue, forKey: SettingsKeys.selectedProfile)
        }
    }

    func start() {
        // Avoid forcing the system consent prompt on every launch.
        // User can trigger an explicit prompt via the "Проверить" action.
        refreshAccessibilityStatus(promptIfNeeded: false)
        soundEngine.startIfNeeded()
        capturingKeyboard = inputMonitor.start()
        recordDebug("Keyboard capture started. capturing=\(capturingKeyboard), ax=\(accessibilityGranted), input=\(inputMonitoringGranted)")
    }

    func stop() {
        inputMonitor.stop()
        soundEngine.stop()
        capturingKeyboard = false
        recordDebug("Keyboard capture stopped")
    }

    func refreshAccessibilityStatus(promptIfNeeded: Bool) {
        let status = permissionsController.refreshStatus(promptIfNeeded: promptIfNeeded)
        accessibilityGranted = status.accessibilityGranted
        inputMonitoringGranted = status.inputMonitoringGranted
        if isEnabled {
            soundEngine.startIfNeeded()
            capturingKeyboard = inputMonitor.start()
        }
        recordDebug("Privacy status refreshed. ax=\(accessibilityGranted), input=\(inputMonitoringGranted), capturing=\(capturingKeyboard)")
    }

    func openAccessibilitySettings() {
        permissionsController.openAccessibilitySettings()
    }

    func openInputMonitoringSettings() {
        permissionsController.openInputMonitoringSettings()
    }

    func resetPrivacyPermissions() {
        guard let bundleID = appMetadataProvider.resolveBundleIdentifier() else {
            NSLog("Unable to resolve bundle identifier for TCC reset")
            return
        }
        let plan = AccessRecoveryPlanCoordinator.makePlan()
        for service in plan.tccServicesToReset {
            permissionsController.resetTCC(service: service, bundleID: bundleID)
        }
        openAccessibilitySettings()
        openInputMonitoringSettings()
        accessActionHint = plan.postResetHint
        accessRecoveryCoordinator.schedulePostResetRefresh { [weak self] in
            self?.refreshAccessibilityStatus(promptIfNeeded: false)
        }
        recordDebug("Privacy permissions reset for bundleID=\(bundleID)")
    }

    func runAccessRecoveryWizard() {
        resetPrivacyPermissions()
        recordDebug("Access recovery wizard started")
        let plan = AccessRecoveryPlanCoordinator.makePlan()
        accessRecoveryCoordinator.scheduleWizard(openSettings: { [weak self] in
            self?.openAccessibilitySettings()
            self?.openInputMonitoringSettings()
        }, setHint: { [weak self] in
            self?.accessActionHint = plan.wizardHint
        }, restart: { [weak self] in
            self?.restartApplication()
        })
    }

    func restartApplication() {
        let plan = AccessRecoveryPlanCoordinator.makePlan()
        appRestartController.restartApplication { [weak self] in
            self?.accessActionHint = plan.restartFailureHint
        }
    }

    func checkForUpdatesInteractive() {
        guard !updateCheckInProgress else { return }
        updateCheckInProgress = true
        updateStatusText = "Проверка..."
        recordDebug("Update check started")

        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.updateCheckInProgress = false }

            let currentVersion = self.appMetadataProvider.currentAppVersion()
            let currentBuild = self.appMetadataProvider.currentAppBuildNumber()
            let presentation = await self.updateCheckFlowCoordinator.run(
                currentVersion: currentVersion,
                currentBuild: currentBuild
            )
            self.updateStatusText = presentation.statusText
            self.recordDebug(presentation.debugMessage)
            UpdateCheckActionExecutor.execute(
                presentation.action,
                alertPresenter: self.alertPresenter,
                urlOpener: self.urlOpener
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
        guard !stressTestInProgress else {
            recordDebug("Stress test skipped: already in progress")
            return
        }
        let effectiveDuration = duration.clamped(to: 5 ... 180)
        stressTestInProgress = true
        stressTestProgress = 0
        stressTestStatus = "Запущен (\(Int(effectiveDuration))с)"
        recordDebug("Stress test started. duration=\(Int(effectiveDuration))s, routeSimulation=\(includeOutputRouteSimulation)")

        let originalProfile = selectedProfile
        let profilePlan = StressProfileTransitionCoordinator.prepare(
            currentProfile: selectedProfile,
            fallbackProfile: .kalihBoxWhite
        )
        if profilePlan.switchedFromOriginal {
            selectedProfile = profilePlan.effectiveProfile
            recordDebug("Stress test switched profile customPack -> kalihBoxWhite (to guarantee playable samples)")
        }
        start()
        soundEngine.startIfNeeded()

        defer {
            if StressProfileTransitionCoordinator.shouldRestoreOriginal(switchedFromOriginal: profilePlan.switchedFromOriginal),
               selectedProfile != originalProfile
            {
                selectedProfile = originalProfile
                recordDebug("Stress test restored profile to \(originalProfile.rawValue)")
            }
            stressTestInProgress = false
            stressTestProgress = 1
        }

        let result = await StressTestService.run(
            duration: effectiveDuration,
            includeOutputRouteSimulation: includeOutputRouteSimulation,
            onProgress: { [weak self] progress in
                self?.stressTestProgress = progress
            },
            onDown: { [weak self] keyCode, autorepeat in
                self?.soundEngine.playDown(for: keyCode, autorepeat: autorepeat)
            },
            onUp: { [weak self] keyCode in
                self?.soundEngine.playUp(for: keyCode)
            },
            onRouteRebuild: { [weak self] in
                self?.soundEngine.handleOutputDeviceChanged()
            }
        )

        stressTestStatus = "ОК · \(Int(result.elapsed.rounded()))с · down \(result.downHits) / up \(result.upHits)"
        recordDebug(
            "Stress test finished. elapsed=\(String(format: "%.2f", result.elapsed))s, " +
                "down=\(result.downHits), up=\(result.upHits), routeRebuilds=\(result.routeRebuilds)"
        )
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
        volume = settings.volume
        variation = settings.variation
        pitchVariation = settings.pitchVariation
        pressLevel = settings.pressLevel
        releaseLevel = settings.releaseLevel
        spaceLevel = settings.spaceLevel
        stackModeEnabled = settings.stackModeEnabled
        limiterEnabled = settings.limiterEnabled
        limiterDrive = settings.limiterDrive
        minInterKeyGapMs = settings.minInterKeyGapMs
        releaseDuckingStrength = settings.releaseDuckingStrength
        releaseDuckingWindowMs = settings.releaseDuckingWindowMs
        releaseTailTightness = settings.releaseTailTightness
    }

    func playABComparison() {
        guard !isABPlaying else { return }
        isABPlaying = true

        let originalCompensationEnabled = dynamicCompensationEnabled
        let originalAdaptationEnabled = typingAdaptiveEnabled
        let originalLimiterEnabled = limiterEnabled
        let originalCompensationStrength = compensationStrength
        let originalVolume = volume
        let originalPressLevel = pressLevel
        let originalReleaseLevel = releaseLevel
        let originalSpaceLevel = spaceLevel
        let originalSystemVolume = lastSystemVolume

        Task { @MainActor [weak self] in
            guard let self else { return }

            switch self.abFeature {
            case .core:
                self.volume = 1.0
                self.pressLevel = 1.5
                self.releaseLevel = 1.1
                self.spaceLevel = 1.5
                self.compensationStrength = 2.0
                self.lastSystemVolume = 0.1
                self.updateDynamicCompensation()
                self.dynamicCompensationEnabled = false
                self.limiterEnabled = false
                await self.playABStressBurst()
                try? await Task.sleep(nanoseconds: 220_000_000)
                self.dynamicCompensationEnabled = true
                self.limiterEnabled = true
                self.updateDynamicCompensation()
                await self.playABStressBurst()
            case .compensation:
                self.volume = 1.0
                self.pressLevel = 1.5
                self.releaseLevel = 1.1
                self.spaceLevel = 1.5
                self.compensationStrength = 2.0
                self.lastSystemVolume = 0.1
                self.updateDynamicCompensation()
                self.dynamicCompensationEnabled = false
                await self.playABStressBurst()
                try? await Task.sleep(nanoseconds: 220_000_000)
                self.dynamicCompensationEnabled = true
                self.updateDynamicCompensation()
                await self.playABStressBurst()
            case .adaptation:
                self.typingAdaptiveEnabled = false
                self.playTestSound()
                try? await Task.sleep(nanoseconds: 350_000_000)
                self.typingAdaptiveEnabled = true
                self.playTestSound()
            case .limiter:
                self.volume = 1.0
                self.pressLevel = 1.5
                self.releaseLevel = 1.1
                self.spaceLevel = 1.5
                self.limiterEnabled = false
                await self.playABStressBurst()
                try? await Task.sleep(nanoseconds: 220_000_000)
                self.limiterEnabled = true
                await self.playABStressBurst()
            }

            try? await Task.sleep(nanoseconds: 120_000_000)
            self.dynamicCompensationEnabled = originalCompensationEnabled
            self.typingAdaptiveEnabled = originalAdaptationEnabled
            self.limiterEnabled = originalLimiterEnabled
            self.compensationStrength = originalCompensationStrength
            self.volume = originalVolume
            self.pressLevel = originalPressLevel
            self.releaseLevel = originalReleaseLevel
            self.spaceLevel = originalSpaceLevel
            self.lastSystemVolume = originalSystemVolume
            self.updateDynamicCompensation()
            self.isABPlaying = false
        }
    }

    private func playABStressBurst() async {
        soundEngine.startIfNeeded()
        for key in [49, 36, 51, 0, 49] {
            soundEngine.playDown(for: key, autorepeat: false)
            if playKeyUp {
                soundEngine.playUp(for: key)
            }
            try? await Task.sleep(nanoseconds: 65_000_000)
        }
    }

    func exportSettings() {
        let state = ProfileSettingsState(
            selectedProfile: selectedProfile,
            volume: volume,
            variation: variation,
            playKeyUp: playKeyUp,
            pressLevel: pressLevel,
            releaseLevel: releaseLevel,
            spaceLevel: spaceLevel
        )
        switch profileSettingsTransferCoordinator.exportSettings(from: state) {
        case .cancelled:
            break
        case let .success(path):
            recordDebug("Settings exported: \(path)")
        case let .failure(message):
            recordDebug("Failed to export settings: \(message)")
        }
    }

    func importSettings() {
        let (result, importedState) = profileSettingsTransferCoordinator.importSettings(fallbackProfile: selectedProfile)
        switch result {
        case .cancelled:
            break
        case let .success(path):
            if let importedState {
                applyImportedProfileSettings(importedState)
            }
            recordDebug("Settings imported: \(path)")
        case let .failure(message):
            recordDebug("Failed to import settings: \(message)")
        }
    }

    private func applyImportedProfileSettings(_ state: ProfileSettingsState) {
        applySoundStatePatch(SoundStatePatchMapper.importedProfilePatch(from: state))
    }

    func clearDebugLog() {
        debugLogService.clear()
        debugLogPreview = "Лог очищен."
        recordDebug("Debug log cleared")
    }

    func exportDebugLog() {
        let runtimeContext = DiagnosticsRuntimeContextMapper.map(DiagnosticsRuntimeContextInput(
            outputDeviceName: currentOutputDeviceName,
            outputUID: currentOutputDeviceUID,
            accessibilityGranted: accessibilityGranted,
            inputMonitoringGranted: inputMonitoringGranted,
            capturingKeyboard: capturingKeyboard,
            systemVolumeAvailable: detectedSystemVolumeAvailable,
            systemVolumePercent: detectedSystemVolumePercent,
            runtimeSettings: snapshotSummaryLines(),
            stressTestStatus: stressTestStatus
        ))
        let runtimeSnapshot = diagnosticsSnapshotFactory.makeSnapshot(context: runtimeContext)
        switch debugLogExportCoordinator.exportDebugLog(
            runtimeSnapshot: runtimeSnapshot,
            debugLogService: debugLogService,
            defaultFileName: "klac-debug-\(DiagnosticsTimestampProvider.fileTimestamp()).log"
        ) {
        case .cancelled:
            break
        case let .success(path):
            recordDebug("Debug log exported: \(path)")
        case let .failure(message):
            recordDebug("Failed to export debug log: \(message)")
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
        let pollState = SystemAudioPollState(
            detectedSystemVolumeAvailable: detectedSystemVolumeAvailable,
            detectedSystemVolumePercent: detectedSystemVolumePercent,
            lastSystemVolume: lastSystemVolume,
            lastOutputDeviceID: lastOutputDeviceID,
            currentOutputDeviceUID: currentOutputDeviceUID,
            currentOutputDeviceName: currentOutputDeviceName,
            initialOutputDeviceResolved: initialOutputDeviceResolved
        )
        let result = SystemAudioPollCoordinator.process(payload: payload, state: pollState)

        detectedSystemVolumeAvailable = result.state.detectedSystemVolumeAvailable
        detectedSystemVolumePercent = result.state.detectedSystemVolumePercent
        lastSystemVolume = result.state.lastSystemVolume
        lastOutputDeviceID = result.state.lastOutputDeviceID
        currentOutputDeviceUID = result.state.currentOutputDeviceUID
        currentOutputDeviceName = result.state.currentOutputDeviceName
        initialOutputDeviceResolved = result.state.initialOutputDeviceResolved

        let volumeChanged = result.volumeChanged
        let availabilityChanged = result.availabilityChanged
        let deviceChanged = result.deviceChanged
        if deviceChanged {
            handleOutputDeviceTransition(result: result)
        }
        if availabilityChanged && !deviceChanged {
            soundEngine.handleOutputDeviceChanged()
            recordDebug("Output stream availability changed. Rebuilt audio graph")
        }

        if volumeChanged || deviceChanged || availabilityChanged {
            updateDynamicCompensation()
        }
    }

    private func handleOutputDeviceTransition(result: SystemAudioPollResult) {
        let deviceUID = result.deviceUID
        let deviceName = result.deviceName
        let transitionContext = OutputDeviceTransitionContext(
            perDeviceSoundProfileEnabled: perDeviceSoundProfileEnabled,
            previousDeviceUID: result.previousDeviceUID,
            newDeviceUID: deviceUID,
            isInitialProbe: result.isInitialProbe,
            hasPersistedPrimarySettings: hasPersistedPrimarySettings
        )
        let beginPlan = OutputDeviceTransitionCoordinator.beginPlan(for: transitionContext)
        if beginPlan.shouldSavePreviousSnapshot {
            saveSnapshot(for: result.previousDeviceUID)
        }
        currentOutputDeviceBoost = perDeviceSnapshotService.boost(for: deviceUID)
        soundEngine.handleOutputDeviceChanged()
        var restored = false
        if beginPlan.shouldAttemptRestoreSnapshot {
            restored = restoreSnapshot(for: deviceUID)
        }
        let finalizePlan = OutputDeviceTransitionCoordinator.finalizePlan(
            for: transitionContext,
            restoredSnapshot: restored
        )
        switch finalizePlan.presetAction {
        case .applyAutoPreset:
            applyAutoOutputPresetIfNeeded(deviceUID: deviceUID, deviceName: deviceName)
        case .markSavedSettings, .markDeviceProfile:
            break
        }
        if let statusLabel = finalizePlan.statusLabel {
            autoOutputPresetLastApplied = statusLabel
        }
        if finalizePlan.shouldSaveNewSnapshot {
            saveSnapshot(for: deviceUID)
        }
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
        let now = CFAbsoluteTimeGetCurrent()

        if systemAudioMonitor.resetStuckPollIfNeeded(now: now, threshold: 6.0) {
            recordDebug("Fail-safe: reset stuck system-volume poll (>6.0s)")
        }

        let plan = FailSafeTickCoordinator.makePlan(
            isEnabled: isEnabled,
            currentlyCapturingKeyboard: capturingKeyboard,
            accessibilityGranted: accessibilityGranted,
            inputMonitoringGranted: inputMonitoringGranted
        )

        if plan.shouldAttemptKeyboardRecovery {
            let restarted = inputMonitor.recoverIfNeeded(
                isEnabled: isEnabled,
                accessibilityGranted: accessibilityGranted,
                inputMonitoringGranted: inputMonitoringGranted,
                currentlyCapturing: capturingKeyboard
            )
            capturingKeyboard = restarted
            if restarted {
                recordDebug("Fail-safe: keyboard capture auto-restarted")
            }
        }

        if plan.shouldRunAudioEngineFailSafe {
            soundEngine.runFailSafeTick()
        }
    }

    private func updateDynamicCompensation() {
        let input = DynamicCompensationInput(
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
        let gain = DynamicCompensationCoordinator.resolveGain(input)
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
        let gain = TypingAdaptationCoordinator.resolveGain(
            TypingAdaptationInput(
                strictVolumeNormalizationEnabled: strictVolumeNormalizationEnabled,
                typingAdaptiveEnabled: typingAdaptiveEnabled,
                typingCPS: typingCPS,
                personalBaselineCPS: typingMetricsService.personalBaselineCPS
            )
        )
        soundEngine.typingSpeedGain = Float(gain)
        if abs(liveTypingGain - gain) > 0.005 {
            liveTypingGain = gain
        }
    }

    private func snapshotSummaryLines() -> [String] {
        let source = RuntimeSettingsSummarySource(
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
        return RuntimeSettingsSummaryBuilder.build(RuntimeSettingsSummaryMapper.map(source))
    }

    private func recordDebug(_ message: String) {
        let timestamp = DiagnosticsTimestampProvider.debugTimestamp()
        _ = debugLogService.append(message: message, timestamp: timestamp)
        debugLogPreview = debugLogService.preview(maxLines: 180)
        NSLog("KlacDebug: \(message)")
    }

    private func saveCurrentDeviceBoost() {
        guard PerDevicePersistenceCoordinator.canPersistBoost(deviceUID: currentOutputDeviceUID) else { return }
        perDeviceSnapshotService.setBoost(currentOutputDeviceBoost, for: currentOutputDeviceUID)
        if PerDevicePersistenceCoordinator.canPersistSnapshot(
            perDeviceSoundProfileEnabled: perDeviceSoundProfileEnabled,
            deviceUID: currentOutputDeviceUID
        ) {
            saveSnapshot(for: currentOutputDeviceUID)
        }
    }

    private func persistPerDeviceSnapshotIfNeeded() {
        guard PerDevicePersistenceCoordinator.canPersistSnapshot(
            perDeviceSoundProfileEnabled: perDeviceSoundProfileEnabled,
            deviceUID: currentOutputDeviceUID
        ) else { return }
        saveSnapshot(for: currentOutputDeviceUID)
    }

    private func currentDeviceStateDTO() -> DeviceSoundStateDTO {
        DeviceSoundStateMapper.toDTO(DeviceSoundStateSource(
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
        ))
    }

    private func saveSnapshot(for deviceUID: String) {
        guard !deviceUID.isEmpty else { return }
        perDeviceSnapshotService.saveSnapshot(deviceUID: deviceUID, state: currentDeviceStateDTO())
    }

    private func restoreSnapshot(for deviceUID: String) -> Bool {
        perDeviceSnapshotService.restoreSnapshot(deviceUID: deviceUID) { [weak self] snapshot in
            guard let self else { return }
            applySoundStatePatch(SoundStatePatchMapper.deviceSnapshotPatch(from: snapshot))
        }
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

}
