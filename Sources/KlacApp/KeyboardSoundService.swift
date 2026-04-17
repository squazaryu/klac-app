import AppKit
import CoreAudio
import Foundation
import UniformTypeIdentifiers

@MainActor
final class KeyboardSoundService: ObservableObject {
    typealias ABFeature = KlacABFeature
    typealias AppearanceMode = KlacAppearanceMode
    typealias OutputPresetMode = KlacOutputPresetMode
    typealias LevelTuningMode = KlacLevelTuningMode

    @Published var isEnabled = true {
        didSet { defaults.set(isEnabled, forKey: SettingsKeys.isEnabled) }
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
        didSet { defaults.set(playKeyUp, forKey: SettingsKeys.playKeyUp) }
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
        didSet { defaults.set(autoProfileTuningEnabled, forKey: SettingsKeys.autoProfileTuningEnabled) }
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
        didSet { defaults.set(autoOutputPresetEnabled, forKey: SettingsKeys.autoOutputPresetEnabled) }
    }
    @Published var perDeviceSoundProfileEnabled = true {
        didSet {
            defaults.set(perDeviceSoundProfileEnabled, forKey: SettingsKeys.perDeviceSoundProfileEnabled)
            persistPerDeviceSnapshotIfNeeded()
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
        didSet { defaults.set(appearanceMode.rawValue, forKey: SettingsKeys.appearanceMode) }
    }

    private let soundEngine = ClickSoundEngine()
    private let eventTap = GlobalKeyEventTap()
    @Published var capturingKeyboard = false
    private let defaults = UserDefaults.standard
    private let settingsStore = SettingsStore()
    private let settingsRepository = SettingsRepository()
    private let updateService = KlacUpdateService(owner: "squazaryu", repository: "klac-app")
    private lazy var updateCheckService = UpdateCheckService(fetchLatestRelease: { [updateService] in
        try await updateService.fetchLatestRelease()
    })
    private let debugLogService = DebugLogService(capacity: 1200)
    private let systemAudioMonitor = SystemAudioMonitor()
    private var lastSystemVolume: Double = 1.0
    private var lastOutputDeviceID: AudioObjectID = 0
    private var outputDeviceBoosts: [String: Double] = [:]
    private var currentOutputDeviceUID = ""
    private var lastAutoPresetDeviceUID = ""
    private var lastInputEventAt: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()
    private var failSafeTimer: Timer?
    private let typingMetricsService = TypingMetricsService()
    private var perDeviceSoundSnapshots: [String: DeviceSoundSnapshot] = [:]
    private var appWillTerminateObserver: NSObjectProtocol?
    private var isRestoringPersistedState = false
    private var hasPersistedPrimarySettings = false
    private var initialOutputDeviceResolved = false
    private var debugLogLines: [String] = []
    private static let debugTimestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    init() {
        let persistedState = settingsRepository.loadState()
        hasPersistedPrimarySettings = persistedState.hasPrimaryPersistedSettings
        restorePersistedState(persistedState)
        configureSoundEngine()
        startRuntimeServices()
        configureEventTap()
        updateLaunchAtLogin()
        registerTerminationObserver()
    }

    private func restorePersistedState(_ state: SettingsRepository.State) {
        isRestoringPersistedState = true
        isEnabled = state.isEnabled
        volume = state.volume
        variation = state.variation
        pitchVariation = state.pitchVariation
        playKeyUp = state.playKeyUp
        pressLevel = state.pressLevel
        releaseLevel = state.releaseLevel
        spaceLevel = state.spaceLevel
        autoProfileTuningEnabled = state.autoProfileTuningEnabled
        selectedProfile = state.selectedProfile
        launchAtLogin = state.launchAtLogin
        dynamicCompensationEnabled = state.dynamicCompensationEnabled
        compensationStrength = state.compensationStrength
        levelMacLow = state.levelMacLow
        levelKbdLow = state.levelKbdLow
        levelMacLowMid = state.levelMacLowMid
        levelKbdLowMid = state.levelKbdLowMid
        levelMacMid = state.levelMacMid
        levelKbdMid = state.levelKbdMid
        levelMacHighMid = state.levelMacHighMid
        levelKbdHighMid = state.levelKbdHighMid
        levelMacHigh = state.levelMacHigh
        levelKbdHigh = state.levelKbdHigh
        strictVolumeNormalizationEnabled = state.strictVolumeNormalizationEnabled
        levelTuningMode = state.levelTuningMode
        autoNormalizeTargetAt100 = state.autoNormalizeTargetAt100
        typingAdaptiveEnabled = state.typingAdaptiveEnabled
        stackModeEnabled = state.stackModeEnabled
        stackDensity = state.stackDensity
        layerThresholdSlam = state.layerThresholdSlam
        layerThresholdHard = state.layerThresholdHard
        layerThresholdMedium = state.layerThresholdMedium
        minInterKeyGapMs = state.minInterKeyGapMs
        releaseDuckingStrength = state.releaseDuckingStrength
        releaseDuckingWindowMs = state.releaseDuckingWindowMs
        releaseTailTightness = state.releaseTailTightness
        limiterEnabled = state.limiterEnabled
        limiterDrive = state.limiterDrive
        outputDeviceBoosts = state.outputDeviceBoosts
        perDeviceSoundSnapshots = state.perDeviceSoundSnapshots
        autoOutputPresetEnabled = state.autoOutputPresetEnabled
        perDeviceSoundProfileEnabled = state.perDeviceSoundProfileEnabled
        appearanceMode = state.appearanceMode
        isRestoringPersistedState = false
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
        eventTap.onEvent = { [weak self] type, keyCode, isAutorepeat in
            guard let self, self.isEnabled else { return }
            self.lastInputEventAt = CFAbsoluteTimeGetCurrent()
            if type == .down {
                if isAutorepeat { return }
                self.trackTypingHit()
                self.soundEngine.playDown(for: keyCode, autorepeat: isAutorepeat)
            } else if self.playKeyUp {
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
        defaults.set(value, forKey: key)
        apply(Float(value))
        persistPerDeviceSnapshotIfNeeded()
    }

    private func syncClampedSoundScalar(
        _ value: Double,
        key: String,
        range: ClosedRange<Double>,
        apply: (Float) -> Void,
        afterApply: (() -> Void)? = nil
    ) {
        let clamped = value.clamped(to: range)
        defaults.set(clamped, forKey: key)
        apply(Float(clamped))
        afterApply?()
        persistPerDeviceSnapshotIfNeeded()
    }

    private func syncSoundFlag(_ value: Bool, key: String, apply: (Bool) -> Void) {
        defaults.set(value, forKey: key)
        apply(value)
        persistPerDeviceSnapshotIfNeeded()
    }

    private func syncCompensationScalar(_ value: Double, key: String, clampedTo range: ClosedRange<Double>? = nil) {
        let persisted = range.map { value.clamped(to: $0) } ?? value
        defaults.set(persisted, forKey: key)
        updateDynamicCompensation()
    }

    private func syncCompensationMode(_ rawValue: String, key: String) {
        defaults.set(rawValue, forKey: key)
        updateDynamicCompensation()
    }

    private func syncLayerThreshold(_ value: Double, key: String) {
        defaults.set(value, forKey: key)
        applyLayerThresholds()
    }

    private func syncDynamicCompensationFlag(_ enabled: Bool, key: String) {
        defaults.set(enabled, forKey: key)
        updateSystemVolumeMonitoringState()
        updateDynamicCompensation()
    }

    private func syncStrictNormalizationFlag(_ enabled: Bool, key: String) {
        defaults.set(enabled, forKey: key)
        soundEngine.strictLevelingEnabled = enabled
        updateDynamicCompensation()
        updateTypingDecayMonitoringState()
        updateTypingAdaptation()
    }

    private func syncTypingAdaptationFlag(_ enabled: Bool, key: String) {
        defaults.set(enabled, forKey: key)
        updateTypingDecayMonitoringState()
        updateTypingAdaptation()
    }

    private func syncLaunchAtLoginFlag(_ enabled: Bool, key: String) {
        defaults.set(enabled, forKey: key)
        updateLaunchAtLogin()
    }

    private func syncSelectedProfile(_ profile: SoundProfile) {
        soundEngine.setProfile(profile)
        if !isRestoringPersistedState, autoProfileTuningEnabled {
            applyProfileSoundPreset(for: profile)
        }
        if !isRestoringPersistedState {
            defaults.set(profile.rawValue, forKey: SettingsKeys.selectedProfile)
        }
    }

    func start() {
        // Avoid forcing the system consent prompt on every launch.
        // User can trigger an explicit prompt via the "Проверить" action.
        refreshAccessibilityStatus(promptIfNeeded: false)
        soundEngine.startIfNeeded()
        capturingKeyboard = eventTap.start()
        recordDebug("Keyboard capture started. capturing=\(capturingKeyboard), ax=\(accessibilityGranted), input=\(inputMonitoringGranted)")
    }

    func stop() {
        eventTap.stop()
        soundEngine.stop()
        capturingKeyboard = false
        recordDebug("Keyboard capture stopped")
    }

    func refreshAccessibilityStatus(promptIfNeeded: Bool) {
        let status = PermissionsService.refreshStatus(promptIfNeeded: promptIfNeeded)
        accessibilityGranted = status.accessibilityGranted
        inputMonitoringGranted = status.inputMonitoringGranted
        if isEnabled {
            soundEngine.startIfNeeded()
            capturingKeyboard = eventTap.start()
        }
        recordDebug("Privacy status refreshed. ax=\(accessibilityGranted), input=\(inputMonitoringGranted), capturing=\(capturingKeyboard)")
    }

    func openAccessibilitySettings() {
        PermissionsService.openAccessibilitySettings()
    }

    func openInputMonitoringSettings() {
        PermissionsService.openInputMonitoringSettings()
    }

    func resetPrivacyPermissions() {
        guard let bundleID = AppMetadataService.resolveBundleIdentifier() else {
            NSLog("Unable to resolve bundle identifier for TCC reset")
            return
        }
        PermissionsService.resetTCC(service: "Accessibility", bundleID: bundleID)
        PermissionsService.resetTCC(service: "ListenEvent", bundleID: bundleID)
        openAccessibilitySettings()
        openInputMonitoringSettings()
        accessActionHint = "Доступы сброшены. Включи Klac в Универсальном доступе и Мониторинге ввода, затем перезапусти приложение."
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.refreshAccessibilityStatus(promptIfNeeded: false)
        }
        recordDebug("Privacy permissions reset for bundleID=\(bundleID)")
    }

    func runAccessRecoveryWizard() {
        resetPrivacyPermissions()
        recordDebug("Access recovery wizard started")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.openAccessibilitySettings()
            self?.openInputMonitoringSettings()
            self?.accessActionHint = "Открыл Универсальный доступ и Мониторинг ввода. После перезапуска включи Klac в обоих списках."
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { [weak self] in
            self?.restartApplication()
        }
    }

    func restartApplication() {
        if let appURL = AppMetadataService.resolveAppBundleURL() {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = false
            config.createsNewApplicationInstance = true
            NSWorkspace.shared.openApplication(at: appURL, configuration: config) { _, error in
                if let error {
                    NSLog("Primary relaunch failed: \(error). Falling back to detached open.")
                    DispatchQueue.main.async { [weak self] in
                        self?.relaunchWithDetachedOpen(appURL: appURL)
                    }
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    NSApplication.shared.terminate(nil)
                }
            }
            return
        }

        // Development run (e.g. `swift run`) without a .app bundle.
        guard let executableURL = Bundle.main.executableURL else {
            NSLog("Failed to resolve app bundle or executable URL for relaunch")
            return
        }
        if relaunchWithDetachedExecutable(executableURL: executableURL) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                NSApplication.shared.terminate(nil)
            }
        } else {
            accessActionHint = "Не удалось автоматом перезапустить dev-сборку. Закрой приложение и запусти снова через swift run."
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

            do {
                let currentVersion = AppMetadataService.currentAppVersion()
                let currentBuild = AppMetadataService.currentAppBuildNumber()
                let result = try await self.updateCheckService.check(
                    currentVersion: currentVersion,
                    currentBuild: currentBuild
                )

                switch result {
                case .upToDate:
                    self.updateStatusText = "У вас актуальная версия (\(currentVersion))."
                    self.recordDebug("Update check: already up to date (\(currentVersion))")
                    self.presentInfoAlert(
                        title: "Обновлений нет",
                        message: "Текущая версия \(currentVersion) уже актуальна."
                    )
                case .invalidReleaseLink(let latestVersion):
                    self.updateStatusText = "Некорректная ссылка релиза."
                    self.recordDebug("Update check: invalid release URL for \(latestVersion)")
                    self.presentInfoAlert(
                        title: "Обновление недоступно",
                        message: "Новая версия \(latestVersion) найдена, но ссылка на релиз некорректна."
                    )
                case .updateAvailable(let latestVersion, let releaseURL):
                    self.updateStatusText = "Найдена версия \(latestVersion). Открываю релиз..."
                    self.recordDebug("Update check: newer version found \(latestVersion), opening release page")
                    NSWorkspace.shared.open(releaseURL)
                }
            } catch {
                self.updateStatusText = "Ошибка обновления: \(error.localizedDescription)"
                self.recordDebug("Update check failed: \(error.localizedDescription)")
                self.presentInfoAlert(
                    title: "Ошибка обновления",
                    message: error.localizedDescription
                )
            }
        }
    }

    private func presentInfoAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func relaunchWithDetachedOpen(appURL: URL) {
        let escapedPath = appURL.path.replacingOccurrences(of: "'", with: "'\\''")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/nohup")
        process.arguments = ["/bin/sh", "-c", "sleep 0.35; /usr/bin/open -n '\(escapedPath)'"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                NSApplication.shared.terminate(nil)
            }
        } catch {
            NSLog("Detached relaunch failed: \(error)")
        }
    }

    private func relaunchWithDetachedExecutable(executableURL: URL) -> Bool {
        let escapedPath = executableURL.path.replacingOccurrences(of: "'", with: "'\\''")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/nohup")
        process.arguments = ["/bin/sh", "-c", "sleep 0.35; '\(escapedPath)' >/dev/null 2>&1 &"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            return true
        } catch {
            NSLog("Detached executable relaunch failed: \(error)")
            return false
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

        if selectedProfile == .customPack {
            selectedProfile = .kalihBoxWhite
            recordDebug("Stress test switched profile customPack -> kalihBoxWhite (to guarantee playable samples)")
        }
        start()
        soundEngine.startIfNeeded()

        defer {
            if selectedProfile != originalProfile {
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
        guard let preset = SoundPresetService.profilePreset(for: profile) else {
            profilePresetLastApplied = "Базовый пресет"
            return
        }
        applySoundSettings(preset.settings)
        profilePresetLastApplied = preset.label
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
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "klac-profile.json"
        panel.title = "Экспорт настроек профиля"
        panel.message = "Сохранить текущие настройки звука"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let snapshot = SettingsSnapshot(
            profile: selectedProfile.rawValue,
            volume: volume,
            variation: variation,
            playKeyUp: playKeyUp,
            pressLevel: pressLevel,
            releaseLevel: releaseLevel,
            spaceLevel: spaceLevel
        )
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: url, options: .atomic)
            recordDebug("Settings exported: \(url.path)")
        } catch {
            recordDebug("Failed to export settings: \(error.localizedDescription)")
        }
    }

    func importSettings() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Импорт настроек профиля"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let data = try Data(contentsOf: url)
            let snapshot = try JSONDecoder().decode(SettingsSnapshot.self, from: data)
            if let profile = SoundProfile(rawValue: snapshot.profile) {
                selectedProfile = profile
            }
            volume = snapshot.volume.clamped(to: 0.0 ... 1.0)
            variation = snapshot.variation.clamped(to: 0.0 ... 1.0)
            playKeyUp = snapshot.playKeyUp
            pressLevel = snapshot.pressLevel.clamped(to: 0.2 ... 1.6)
            releaseLevel = snapshot.releaseLevel.clamped(to: 0.1 ... 1.4)
            spaceLevel = snapshot.spaceLevel.clamped(to: 0.2 ... 1.8)
            recordDebug("Settings imported: \(url.path)")
        } catch {
            recordDebug("Failed to import settings: \(error.localizedDescription)")
        }
    }

    func clearDebugLog() {
        debugLogService.clear()
        debugLogLines = debugLogService.lines
        debugLogPreview = "Лог очищен."
        recordDebug("Debug log cleared")
    }

    func exportDebugLog() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "klac-debug-\(Self.fileTimestamp()).log"
        panel.title = "Экспорт debug-логов"
        panel.message = "Сохранить диагностический лог приложения"
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let report = buildDebugReport()
        do {
            try report.write(to: url, atomically: true, encoding: .utf8)
            recordDebug("Debug log exported: \(url.path)")
        } catch {
            recordDebug("Failed to export debug log: \(error.localizedDescription)")
        }
    }

    private func updateLaunchAtLogin() {
        do {
            try LaunchAtLoginService.setEnabled(launchAtLogin)
        } catch {
            NSLog("Failed to update launch at login: \(error)")
        }
    }

    private func startSystemVolumeMonitoring(interval: TimeInterval) {
        systemAudioMonitor.start(interval: interval) { [weak self] payload in
            self?.handleSystemAudioPoll(payload)
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
        let wasVolumeAvailable = detectedSystemVolumeAvailable
        detectedSystemVolumeAvailable = payload.scalar != nil
        if let scalar = payload.scalar {
            detectedSystemVolumePercent = scalar * 100.0
        }

        let nextVolume = payload.scalar ?? lastSystemVolume
        let volumeChanged = abs(lastSystemVolume - nextVolume) > 0.005
        if volumeChanged {
            lastSystemVolume = nextVolume
        }

        let deviceID = payload.deviceID
        let deviceUID = payload.deviceUID
        let deviceName = payload.deviceName
        let deviceChanged = deviceID != lastOutputDeviceID || deviceUID != currentOutputDeviceUID
        if deviceChanged {
            let isInitialProbe = !initialOutputDeviceResolved
            let previousUID = currentOutputDeviceUID
            if perDeviceSoundProfileEnabled, !previousUID.isEmpty {
                saveSnapshot(for: previousUID)
            }
            lastOutputDeviceID = deviceID
            currentOutputDeviceUID = deviceUID
            currentOutputDeviceName = deviceName
            currentOutputDeviceBoost = outputDeviceBoosts[deviceUID] ?? 1.0
            soundEngine.handleOutputDeviceChanged()
            var restored = false
            if perDeviceSoundProfileEnabled, !deviceUID.isEmpty {
                restored = restoreSnapshot(for: deviceUID)
            }
            if !restored {
                let shouldApplyAutoPreset = !isInitialProbe || !hasPersistedPrimarySettings
                if shouldApplyAutoPreset {
                    applyAutoOutputPresetIfNeeded(deviceUID: deviceUID, deviceName: deviceName)
                } else {
                    autoOutputPresetLastApplied = "Сохраненные настройки"
                }
                if perDeviceSoundProfileEnabled, !deviceUID.isEmpty {
                    saveSnapshot(for: deviceUID)
                }
            } else {
                autoOutputPresetLastApplied = "Профиль устройства"
            }
            initialOutputDeviceResolved = true
            recordDebug("Output device changed: \(deviceName) [uid=\(deviceUID.isEmpty ? "n/a" : deviceUID)]")
        }

        let availabilityChanged = wasVolumeAvailable != detectedSystemVolumeAvailable
        if availabilityChanged && !deviceChanged {
            soundEngine.handleOutputDeviceChanged()
            recordDebug("Output stream availability changed. Rebuilt audio graph")
        }

        if volumeChanged || deviceChanged || availabilityChanged {
            updateDynamicCompensation()
        }
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

        if isEnabled, !capturingKeyboard, accessibilityGranted, inputMonitoringGranted {
            let restarted = eventTap.start()
            capturingKeyboard = restarted
            if restarted {
                recordDebug("Fail-safe: keyboard capture auto-restarted")
            }
        }

        if isEnabled {
            soundEngine.runFailSafeTick()
        }
    }

    private func updateDynamicCompensation() {
        var gain: Double
        if strictVolumeNormalizationEnabled {
            if levelTuningMode == .simple {
                gain = AudioCompensationMath.autoInverseGain(
                    systemVolumeScalar: lastSystemVolume,
                    targetAt100: autoNormalizeTargetAt100
                )
            } else {
                gain = strictCurveGain(systemVolume: lastSystemVolume)
            }
        } else {
            gain = curveGainAt(systemVolume: lastSystemVolume)
        }
        gain *= currentOutputDeviceBoost

        if dynamicCompensationEnabled && !strictVolumeNormalizationEnabled {
            let lowVolumeFactor = max(0.0, 1.0 - lastSystemVolume)
            gain *= 1.0 + lowVolumeFactor * (0.18 + compensationStrength * 0.95)
        }

        let clamped = Float(gain).clamped(to: 0.20 ... 6.0)
        soundEngine.dynamicCompensationGain = clamped
        let next = Double(clamped)
        if abs(liveDynamicGain - next) > 0.005 {
            liveDynamicGain = next
        }
    }

    private func curveGainAt(systemVolume: Double) -> Double {
        Self.curveGain(
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
        let base = curveGainAt(systemVolume: systemVolume)
        let at100 = max(0.001, curveGainAt(systemVolume: 1.0))
        let target = autoNormalizeTargetAt100.clamped(to: 0.20 ... 1.20)
        let scale = target / at100
        return (base * scale).clamped(to: 0.20 ... 12.0)
    }

    private func applyLayerThresholds() {
        let slam = layerThresholdSlam.clamped(to: 0.010 ... 0.120)
        let hard = max(slam + 0.006, layerThresholdHard).clamped(to: 0.025 ... 0.180)
        let medium = max(hard + 0.006, layerThresholdMedium).clamped(to: 0.040 ... 0.260)
        soundEngine.setVelocityThresholds(slam: slam, hard: hard, medium: medium)
    }

    private func applyAutoOutputPresetIfNeeded(deviceUID: String, deviceName: String) {
        guard autoOutputPresetEnabled else { return }
        guard !deviceUID.isEmpty else { return }
        guard deviceUID != lastAutoPresetDeviceUID else { return }
        lastAutoPresetDeviceUID = deviceUID

        if OutputDeviceClassifier.looksLikeHeadphones(deviceName) {
            applyHeadphonesPreset()
            autoOutputPresetLastApplied = "Наушники"
        } else {
            applySpeakersPreset()
            autoOutputPresetLastApplied = "Динамики"
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

    nonisolated private static func curveGain(
        systemVolume: Double,
        macLow: Double,
        kbdLow: Double,
        macLowMid: Double,
        kbdLowMid: Double,
        macMid: Double,
        kbdMid: Double,
        macHighMid: Double,
        kbdHighMid: Double,
        macHigh: Double,
        kbdHigh: Double
    ) -> Double {
        let points = [
            GainCurvePoint(x: macLow.clamped(to: 0.05 ... 0.90), y: kbdLow.clamped(to: 0.20 ... 4.00)),
            GainCurvePoint(x: macLowMid.clamped(to: 0.08 ... 0.93), y: kbdLowMid.clamped(to: 0.20 ... 4.00)),
            GainCurvePoint(x: macMid.clamped(to: 0.05 ... 0.95), y: kbdMid.clamped(to: 0.20 ... 4.00)),
            GainCurvePoint(x: macHighMid.clamped(to: 0.10 ... 0.98), y: kbdHighMid.clamped(to: 0.20 ... 4.00)),
            GainCurvePoint(x: macHigh.clamped(to: 0.10 ... 1.00), y: kbdHigh.clamped(to: 0.20 ... 4.00))
        ]
        return AudioCompensationMath.curveGain(systemVolume: systemVolume, points: points)
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
        if strictVolumeNormalizationEnabled {
            soundEngine.typingSpeedGain = 1.0
            liveTypingGain = 1.0
            return
        }
        guard typingAdaptiveEnabled else {
            soundEngine.typingSpeedGain = 1.0
            liveTypingGain = 1.0
            return
        }
        // Fully automatic adaptation to personal typing speed.
        let target = max(2.5, typingMetricsService.personalBaselineCPS * 1.1)
        let normalized = (typingCPS / target).clamped(to: 0.0 ... 1.6)
        let gain = 1.0 + 0.25 + normalized * 0.95
        let clamped = gain.clamped(to: 1.0 ... 2.5)
        soundEngine.typingSpeedGain = Float(clamped)
        if abs(liveTypingGain - clamped) > 0.005 {
            liveTypingGain = clamped
        }
    }

    private func buildDebugReport() -> String {
        let context = DebugReportContext(
            generatedAt: Self.debugTimestampFormatter.string(from: Date()),
            appVersion: AppMetadataService.currentAppVersion(),
            buildNumber: String(AppMetadataService.currentAppBuildNumber()),
            buildTag: Bundle.main.object(forInfoDictionaryKey: "KlacBuildTag") as? String ?? "n/a",
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            outputDeviceName: currentOutputDeviceName,
            outputUID: currentOutputDeviceUID.isEmpty ? "n/a" : currentOutputDeviceUID,
            accessibilityGranted: accessibilityGranted,
            inputMonitoringGranted: inputMonitoringGranted,
            capturingKeyboard: capturingKeyboard,
            systemVolumeAvailable: detectedSystemVolumeAvailable,
            systemVolumePercent: detectedSystemVolumePercent,
            runtimeSettings: snapshotSummaryLines(),
            stressTestStatus: stressTestStatus
        )
        return debugLogService.buildReport(context: context, latestCrashSection: latestCrashReportSection())
    }

    private var soundSettingsModel: SoundSettings {
        SoundSettings(
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
            releaseTailTightness: releaseTailTightness
        )
    }

    private var compensationSettingsModel: CompensationSettings {
        CompensationSettings(
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
            strictVolumeNormalizationEnabled: strictVolumeNormalizationEnabled
        )
    }

    private var systemSettingsModel: SystemSettings {
        SystemSettings(
            launchAtLogin: launchAtLogin,
            autoOutputPresetEnabled: autoOutputPresetEnabled,
            perDeviceSoundProfileEnabled: perDeviceSoundProfileEnabled,
            appearanceModeRawValue: appearanceMode.rawValue
        )
    }

    private func snapshotSummaryLines() -> [String] {
        let sound = soundSettingsModel
        let comp = compensationSettingsModel
        let system = systemSettingsModel
        return [
            "- profile=\(selectedProfile.rawValue)",
            "- volume=\(String(format: "%.3f", sound.volume))",
            "- variation=\(String(format: "%.3f", sound.variation))",
            "- pitchVariation=\(String(format: "%.3f", sound.pitchVariation))",
            "- pressLevel=\(String(format: "%.3f", sound.pressLevel))",
            "- releaseLevel=\(String(format: "%.3f", sound.releaseLevel))",
            "- spaceLevel=\(String(format: "%.3f", sound.spaceLevel))",
            "- dynamicCompensationEnabled=\(comp.dynamicCompensationEnabled)",
            "- strictVolumeNormalizationEnabled=\(comp.strictVolumeNormalizationEnabled)",
            "- typingAdaptiveEnabled=\(typingAdaptiveEnabled)",
            "- stackModeEnabled=\(sound.stackModeEnabled)",
            "- limiterEnabled=\(sound.limiterEnabled)",
            "- autoOutputPresetEnabled=\(system.autoOutputPresetEnabled)",
            "- perDeviceSoundProfileEnabled=\(system.perDeviceSoundProfileEnabled)"
        ]
    }

    private func latestCrashReportSection() -> String? {
        let diagnosticsRoot = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/DiagnosticReports", isDirectory: true)
        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: diagnosticsRoot,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }
        let candidates = entries.filter { url in
            let name = url.lastPathComponent.lowercased()
            return (name.hasPrefix("klac") || name.hasPrefix("klacapp")) &&
                (name.hasSuffix(".crash") || name.hasSuffix(".ips"))
        }
        guard let latest = candidates.max(by: { lhs, rhs in
            let ld = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let rd = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return ld < rd
        }) else {
            return nil
        }
        guard let data = try? Data(contentsOf: latest),
              let text = String(data: data, encoding: .utf8) else {
            return "Latest crash report: \(latest.path)\n(unable to decode file)"
        }
        let preview = text.split(separator: "\n").prefix(120).joined(separator: "\n")
        return """
        Latest crash report: \(latest.path)
        ----
        \(preview)
        ----
        """
    }

    private func recordDebug(_ message: String) {
        let timestamp = Self.debugTimestampFormatter.string(from: Date())
        _ = debugLogService.append(message: message, timestamp: timestamp)
        debugLogLines = debugLogService.lines
        debugLogPreview = debugLogService.preview(maxLines: 180)
        NSLog("KlacDebug: \(message)")
    }

    private static func fileTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }

    private func saveCurrentDeviceBoost() {
        guard !currentOutputDeviceUID.isEmpty else { return }
        outputDeviceBoosts[currentOutputDeviceUID] = currentOutputDeviceBoost.clamped(to: 0.5 ... 2.0)
        settingsStore.encode(outputDeviceBoosts, forKey: SettingsKeys.outputDeviceBoosts)
        if perDeviceSoundProfileEnabled {
            saveSnapshot(for: currentOutputDeviceUID)
        }
    }

    private func persistPerDeviceSnapshotIfNeeded() {
        guard perDeviceSoundProfileEnabled else { return }
        guard !currentOutputDeviceUID.isEmpty else { return }
        saveSnapshot(for: currentOutputDeviceUID)
    }

    private func currentSnapshot() -> DeviceSoundSnapshot {
        DeviceSoundSnapshot(
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

    private func saveSnapshot(for deviceUID: String) {
        guard !deviceUID.isEmpty else { return }
        perDeviceSoundSnapshots[deviceUID] = currentSnapshot()
        settingsStore.encode(perDeviceSoundSnapshots, forKey: SettingsKeys.perDeviceSoundSnapshots)
    }

    private func restoreSnapshot(for deviceUID: String) -> Bool {
        guard let snapshot = perDeviceSoundSnapshots[deviceUID] else { return false }
        volume = snapshot.volume.clamped(to: 0.0 ... 1.0)
        variation = snapshot.variation.clamped(to: 0.0 ... 1.0)
        pitchVariation = snapshot.pitchVariation.clamped(to: 0.0 ... 0.6)
        pressLevel = snapshot.pressLevel.clamped(to: 0.2 ... 1.6)
        releaseLevel = snapshot.releaseLevel.clamped(to: 0.1 ... 1.4)
        spaceLevel = snapshot.spaceLevel.clamped(to: 0.2 ... 1.8)
        levelMacLowMid = snapshot.levelMacLowMid.clamped(to: 0.08 ... 0.93)
        levelKbdLowMid = snapshot.levelKbdLowMid.clamped(to: 0.20 ... 4.00)
        levelMacHighMid = snapshot.levelMacHighMid.clamped(to: 0.10 ... 0.98)
        levelKbdHighMid = snapshot.levelKbdHighMid.clamped(to: 0.20 ... 4.00)
        stackModeEnabled = snapshot.stackModeEnabled
        limiterEnabled = snapshot.limiterEnabled
        limiterDrive = snapshot.limiterDrive.clamped(to: 0.6 ... 2.0)
        minInterKeyGapMs = snapshot.minInterKeyGapMs.clamped(to: 0 ... 45)
        releaseDuckingStrength = snapshot.releaseDuckingStrength.clamped(to: 0 ... 1)
        releaseDuckingWindowMs = snapshot.releaseDuckingWindowMs.clamped(to: 20 ... 180)
        releaseTailTightness = snapshot.releaseTailTightness.clamped(to: 0 ... 1)
        currentOutputDeviceBoost = snapshot.currentOutputDeviceBoost.clamped(to: 0.5 ... 2.0)
        return true
    }

}
