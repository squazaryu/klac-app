import AppKit
import AVFoundation
import ApplicationServices
import CoreAudio
import Foundation
import ServiceManagement
import UniformTypeIdentifiers

@MainActor
final class KeyboardSoundService: ObservableObject {
    enum ABFeature: String, CaseIterable, Identifiable {
        case core
        case compensation
        case limiter
        case adaptation

        var id: String { rawValue }

        var title: String {
            switch self {
            case .core: return "Компенсация + Лимитер"
            case .compensation: return "Компенсация"
            case .limiter: return "Лимитер"
            case .adaptation: return "Адаптация"
            }
        }
    }

    enum AppearanceMode: String, CaseIterable, Identifiable {
        case system
        case light
        case dark

        var id: String { rawValue }

        var title: String {
            switch self {
            case .system: return "Системная"
            case .light: return "Светлая"
            case .dark: return "Темная"
            }
        }
    }

    @Published var isEnabled = true {
        didSet { defaults.set(isEnabled, forKey: Keys.isEnabled) }
    }
    @Published var accessibilityGranted = false
    @Published var inputMonitoringGranted = false
    @Published var accessActionHint: String?
    @Published var volume: Double = 0.75 {
        didSet {
            soundEngine.masterVolume = Float(volume)
            defaults.set(volume, forKey: Keys.volume)
        }
    }
    @Published var variation: Double = 0.3 {
        didSet {
            soundEngine.variation = Float(variation)
            defaults.set(variation, forKey: Keys.variation)
        }
    }
    @Published var playKeyUp = true {
        didSet { defaults.set(playKeyUp, forKey: Keys.playKeyUp) }
    }
    @Published var pressLevel: Double = 1.0 {
        didSet {
            soundEngine.pressLevel = Float(pressLevel)
            defaults.set(pressLevel, forKey: Keys.pressLevel)
        }
    }
    @Published var releaseLevel: Double = 0.65 {
        didSet {
            soundEngine.releaseLevel = Float(releaseLevel)
            defaults.set(releaseLevel, forKey: Keys.releaseLevel)
        }
    }
    @Published var spaceLevel: Double = 1.1 {
        didSet {
            soundEngine.spaceLevel = Float(spaceLevel)
            defaults.set(spaceLevel, forKey: Keys.spaceLevel)
        }
    }
    @Published var selectedProfile: SoundProfile = .kalihBoxWhite {
        didSet {
            soundEngine.setProfile(selectedProfile)
            defaults.set(selectedProfile.rawValue, forKey: Keys.selectedProfile)
        }
    }
    @Published var launchAtLogin = false {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            updateLaunchAtLogin()
        }
    }
    @Published var dynamicCompensationEnabled = false {
        didSet {
            defaults.set(dynamicCompensationEnabled, forKey: Keys.dynamicCompensationEnabled)
            updateSystemVolumeMonitoringState()
            updateDynamicCompensation()
        }
    }
    @Published var compensationStrength: Double = 1.0 {
        didSet {
            defaults.set(compensationStrength, forKey: Keys.compensationStrength)
            updateDynamicCompensation()
        }
    }
    @Published var levelMacLow: Double = 0.30 {
        didSet {
            defaults.set(levelMacLow.clamped(to: 0.05 ... 0.90), forKey: Keys.levelMacLow)
            updateDynamicCompensation()
        }
    }
    @Published var levelKbdLow: Double = 1.60 {
        didSet {
            defaults.set(levelKbdLow.clamped(to: 0.20 ... 4.00), forKey: Keys.levelKbdLow)
            updateDynamicCompensation()
        }
    }
    @Published var levelMacMid: Double = 0.60 {
        didSet {
            defaults.set(levelMacMid.clamped(to: 0.05 ... 0.95), forKey: Keys.levelMacMid)
            updateDynamicCompensation()
        }
    }
    @Published var levelKbdMid: Double = 1.00 {
        didSet {
            defaults.set(levelKbdMid.clamped(to: 0.20 ... 4.00), forKey: Keys.levelKbdMid)
            updateDynamicCompensation()
        }
    }
    @Published var levelMacHigh: Double = 1.00 {
        didSet {
            defaults.set(levelMacHigh.clamped(to: 0.10 ... 1.00), forKey: Keys.levelMacHigh)
            updateDynamicCompensation()
        }
    }
    @Published var levelKbdHigh: Double = 0.45 {
        didSet {
            defaults.set(levelKbdHigh.clamped(to: 0.20 ... 4.00), forKey: Keys.levelKbdHigh)
            updateDynamicCompensation()
        }
    }
    @Published var strictVolumeNormalizationEnabled = true {
        didSet {
            defaults.set(strictVolumeNormalizationEnabled, forKey: Keys.strictVolumeNormalizationEnabled)
            soundEngine.strictLevelingEnabled = strictVolumeNormalizationEnabled
            updateDynamicCompensation()
            updateTypingDecayMonitoringState()
            updateTypingAdaptation()
        }
    }
    @Published var autoNormalizeTargetAt100: Double = 0.45 {
        didSet {
            defaults.set(autoNormalizeTargetAt100.clamped(to: 0.20 ... 1.20), forKey: Keys.autoNormalizeTargetAt100)
            updateDynamicCompensation()
        }
    }
    @Published var typingAdaptiveEnabled = false {
        didSet {
            defaults.set(typingAdaptiveEnabled, forKey: Keys.typingAdaptiveEnabled)
            updateTypingDecayMonitoringState()
            updateTypingAdaptation()
        }
    }
    @Published var stackModeEnabled = false {
        didSet {
            defaults.set(stackModeEnabled, forKey: Keys.stackModeEnabled)
            soundEngine.stackModeEnabled = stackModeEnabled
        }
    }
    @Published var stackDensity: Double = 0.55 {
        didSet {
            defaults.set(stackDensity, forKey: Keys.stackDensity)
            soundEngine.stackDensity = Float(stackDensity)
        }
    }
    @Published var limiterEnabled = true {
        didSet {
            defaults.set(limiterEnabled, forKey: Keys.limiterEnabled)
            soundEngine.limiterEnabled = limiterEnabled
        }
    }
    @Published var limiterDrive: Double = 1.2 {
        didSet {
            defaults.set(limiterDrive, forKey: Keys.limiterDrive)
            soundEngine.limiterDrive = Float(limiterDrive)
        }
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
    @Published var appearanceMode: AppearanceMode = .system {
        didSet { defaults.set(appearanceMode.rawValue, forKey: Keys.appearanceMode) }
    }

    private let soundEngine = ClickSoundEngine()
    private let eventTap = GlobalKeyEventTap()
    @Published var capturingKeyboard = false
    private let defaults = UserDefaults.standard
    private var systemVolumeTimer: Timer?
    private var systemMonitorInterval: TimeInterval = 0
    private var lastSystemVolume: Double = 1.0
    private let systemMonitorQueue = DispatchQueue(label: "Klac.SystemAudioMonitor", qos: .utility)
    private var systemPollInFlight = false
    private var lastOutputDeviceID: AudioObjectID = 0
    private var outputDeviceBoosts: [String: Double] = [:]
    private var currentOutputDeviceUID = ""
    private var typingTimestamps: [CFAbsoluteTime] = []
    private var typingDecayTimer: Timer?
    private var personalBaselineCPS: Double = 3.0

    private enum Keys {
        static let isEnabled = "settings.isEnabled"
        static let volume = "settings.volume"
        static let variation = "settings.variation"
        static let playKeyUp = "settings.playKeyUp"
        static let pressLevel = "settings.pressLevel"
        static let releaseLevel = "settings.releaseLevel"
        static let spaceLevel = "settings.spaceLevel"
        static let selectedProfile = "settings.selectedProfile"
        static let launchAtLogin = "settings.launchAtLogin"
        static let dynamicCompensationEnabled = "settings.dynamicCompensationEnabled"
        static let compensationStrength = "settings.compensationStrength"
        static let levelMacLow = "settings.levelMacLow"
        static let levelKbdLow = "settings.levelKbdLow"
        static let levelMacMid = "settings.levelMacMid"
        static let levelKbdMid = "settings.levelKbdMid"
        static let levelMacHigh = "settings.levelMacHigh"
        static let levelKbdHigh = "settings.levelKbdHigh"
        static let strictVolumeNormalizationEnabled = "settings.strictVolumeNormalizationEnabled"
        static let autoNormalizeTargetAt100 = "settings.autoNormalizeTargetAt100"
        static let typingAdaptiveEnabled = "settings.typingAdaptiveEnabled"
        static let stackModeEnabled = "settings.stackModeEnabled"
        static let stackDensity = "settings.stackDensity"
        static let limiterEnabled = "settings.limiterEnabled"
        static let limiterDrive = "settings.limiterDrive"
        static let outputDeviceBoosts = "settings.outputDeviceBoosts"
        static let appearanceMode = "settings.appearanceMode"
    }

    init() {
        if defaults.object(forKey: Keys.isEnabled) != nil {
            isEnabled = defaults.bool(forKey: Keys.isEnabled)
        }
        if defaults.object(forKey: Keys.volume) != nil {
            volume = defaults.double(forKey: Keys.volume)
        }
        if defaults.object(forKey: Keys.variation) != nil {
            variation = defaults.double(forKey: Keys.variation)
        }
        if defaults.object(forKey: Keys.playKeyUp) != nil {
            playKeyUp = defaults.bool(forKey: Keys.playKeyUp)
        }
        if defaults.object(forKey: Keys.pressLevel) != nil {
            pressLevel = defaults.double(forKey: Keys.pressLevel)
        }
        if defaults.object(forKey: Keys.releaseLevel) != nil {
            releaseLevel = defaults.double(forKey: Keys.releaseLevel)
        }
        if defaults.object(forKey: Keys.spaceLevel) != nil {
            spaceLevel = defaults.double(forKey: Keys.spaceLevel)
        }
        if let profileRaw = defaults.string(forKey: Keys.selectedProfile),
           let profile = SoundProfile(rawValue: profileRaw) {
            selectedProfile = profile
        }
        if defaults.object(forKey: Keys.launchAtLogin) != nil {
            launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        }
        if defaults.object(forKey: Keys.dynamicCompensationEnabled) != nil {
            dynamicCompensationEnabled = defaults.bool(forKey: Keys.dynamicCompensationEnabled)
        }
        if defaults.object(forKey: Keys.compensationStrength) != nil {
            compensationStrength = defaults.double(forKey: Keys.compensationStrength)
        }
        if defaults.object(forKey: Keys.levelMacLow) != nil {
            levelMacLow = defaults.double(forKey: Keys.levelMacLow).clamped(to: 0.05 ... 0.90)
        }
        if defaults.object(forKey: Keys.levelKbdLow) != nil {
            levelKbdLow = defaults.double(forKey: Keys.levelKbdLow).clamped(to: 0.20 ... 4.00)
        }
        if defaults.object(forKey: Keys.levelMacMid) != nil {
            levelMacMid = defaults.double(forKey: Keys.levelMacMid).clamped(to: 0.05 ... 0.95)
        }
        if defaults.object(forKey: Keys.levelKbdMid) != nil {
            levelKbdMid = defaults.double(forKey: Keys.levelKbdMid).clamped(to: 0.20 ... 4.00)
        }
        if defaults.object(forKey: Keys.levelMacHigh) != nil {
            levelMacHigh = defaults.double(forKey: Keys.levelMacHigh).clamped(to: 0.10 ... 1.00)
        }
        if defaults.object(forKey: Keys.levelKbdHigh) != nil {
            levelKbdHigh = defaults.double(forKey: Keys.levelKbdHigh).clamped(to: 0.20 ... 4.00)
        }
        if defaults.object(forKey: Keys.strictVolumeNormalizationEnabled) != nil {
            strictVolumeNormalizationEnabled = defaults.bool(forKey: Keys.strictVolumeNormalizationEnabled)
        }
        if defaults.object(forKey: Keys.autoNormalizeTargetAt100) != nil {
            autoNormalizeTargetAt100 = defaults.double(forKey: Keys.autoNormalizeTargetAt100).clamped(to: 0.20 ... 1.20)
        }
        if defaults.object(forKey: Keys.typingAdaptiveEnabled) != nil {
            typingAdaptiveEnabled = defaults.bool(forKey: Keys.typingAdaptiveEnabled)
        }
        if defaults.object(forKey: Keys.stackModeEnabled) != nil {
            stackModeEnabled = defaults.bool(forKey: Keys.stackModeEnabled)
        }
        if defaults.object(forKey: Keys.stackDensity) != nil {
            stackDensity = defaults.double(forKey: Keys.stackDensity)
        }
        if defaults.object(forKey: Keys.limiterEnabled) != nil {
            limiterEnabled = defaults.bool(forKey: Keys.limiterEnabled)
        }
        if defaults.object(forKey: Keys.limiterDrive) != nil {
            limiterDrive = defaults.double(forKey: Keys.limiterDrive)
        }
        if let data = defaults.data(forKey: Keys.outputDeviceBoosts),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            outputDeviceBoosts = decoded
        }
        if let modeRaw = defaults.string(forKey: Keys.appearanceMode),
           let mode = AppearanceMode(rawValue: modeRaw) {
            appearanceMode = mode
        }

        soundEngine.masterVolume = Float(volume)
        soundEngine.variation = Float(variation)
        soundEngine.pressLevel = Float(pressLevel)
        soundEngine.releaseLevel = Float(releaseLevel)
        soundEngine.spaceLevel = Float(spaceLevel)
        soundEngine.limiterEnabled = limiterEnabled
        soundEngine.limiterDrive = Float(limiterDrive)
        soundEngine.stackModeEnabled = stackModeEnabled
        soundEngine.stackDensity = Float(stackDensity)
        soundEngine.strictLevelingEnabled = strictVolumeNormalizationEnabled
        soundEngine.setProfile(selectedProfile)
        updateSystemVolumeMonitoringState()
        updateTypingDecayMonitoringState()
        updateDynamicCompensation()
        updateTypingAdaptation()
        refreshAccessibilityStatus(promptIfNeeded: false)

        eventTap.onEvent = { [weak self] type, keyCode, isAutorepeat in
            guard let self, self.isEnabled else { return }
            if type == .down {
                if isAutorepeat { return }
                self.trackTypingHit()
                self.soundEngine.playDown(for: keyCode, autorepeat: isAutorepeat)
            } else if self.playKeyUp {
                self.soundEngine.playUp(for: keyCode)
            }
        }

        updateLaunchAtLogin()
    }

    func start() {
        // Avoid forcing the system consent prompt on every launch.
        // User can trigger an explicit prompt via the "Проверить" action.
        refreshAccessibilityStatus(promptIfNeeded: false)
        soundEngine.startIfNeeded()
        capturingKeyboard = eventTap.start()
        NSLog("Keyboard capture start result: capturingKeyboard=\(capturingKeyboard), accessibilityGranted=\(accessibilityGranted), inputMonitoringGranted=\(inputMonitoringGranted)")
    }

    func stop() {
        eventTap.stop()
        soundEngine.stop()
        capturingKeyboard = false
    }

    func refreshAccessibilityStatus(promptIfNeeded: Bool) {
        if promptIfNeeded {
            let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
            accessibilityGranted = AXIsProcessTrustedWithOptions(options)
            inputMonitoringGranted = Self.preflightInputMonitoring(promptIfNeeded: true)
        } else {
            accessibilityGranted = AXIsProcessTrusted()
            inputMonitoringGranted = Self.preflightInputMonitoring(promptIfNeeded: false)
        }
        if isEnabled {
            soundEngine.startIfNeeded()
            capturingKeyboard = eventTap.start()
        }
        NSLog("Privacy status refreshed: accessibilityGranted=\(accessibilityGranted), inputMonitoringGranted=\(inputMonitoringGranted), capturingKeyboard=\(capturingKeyboard)")
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func openInputMonitoringSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }
    }

    func resetPrivacyPermissions() {
        guard let bundleID = resolveBundleIdentifier() else {
            NSLog("Unable to resolve bundle identifier for TCC reset")
            return
        }
        runTCCReset(service: "Accessibility", bundleID: bundleID)
        runTCCReset(service: "ListenEvent", bundleID: bundleID)
        openAccessibilitySettings()
        openInputMonitoringSettings()
        accessActionHint = "Доступы сброшены. Включи Klac в Универсальном доступе и Мониторинге ввода, затем перезапусти приложение."
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.refreshAccessibilityStatus(promptIfNeeded: false)
        }
    }

    func runAccessRecoveryWizard() {
        resetPrivacyPermissions()
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
        if let appURL = resolveAppBundleURL() {
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

    private func resolveBundleIdentifier() -> String? {
        if let id = Bundle.main.bundleIdentifier, !id.isEmpty {
            return id
        }
        if let id = Bundle.main.object(forInfoDictionaryKey: kCFBundleIdentifierKey as String) as? String,
           !id.isEmpty {
            return id
        }
        if let appURL = resolveAppBundleURL(),
           let bundle = Bundle(url: appURL),
           let id = bundle.bundleIdentifier,
           !id.isEmpty {
            return id
        }
        // Stable fallback for this app build/install pipeline.
        return "com.klacapp.klac"
    }

    private func resolveAppBundleURL() -> URL? {
        // Standard app launch path.
        let mainURL = Bundle.main.bundleURL
        if mainURL.pathExtension == "app" {
            return mainURL
        }

        // Running from executable inside .app/Contents/MacOS.
        if let executableURL = Bundle.main.executableURL {
            var cursor = executableURL
            for _ in 0 ..< 6 {
                let parent = cursor.deletingLastPathComponent()
                if parent.pathExtension == "app" {
                    return parent
                }
                if parent.path == cursor.path { break }
                cursor = parent
            }
        }

        return nil
    }

    func playTestSound() {
        soundEngine.startIfNeeded()
        soundEngine.playDown(for: 0, autorepeat: false)
        if playKeyUp {
            soundEngine.playUp(for: 0)
        }
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
        } catch {
            NSLog("Failed to export settings: \(error)")
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
        } catch {
            NSLog("Failed to import settings: \(error)")
        }
    }

    private func updateLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Failed to update launch at login: \(error)")
        }
    }

    private func startSystemVolumeMonitoring(interval: TimeInterval) {
        systemVolumeTimer?.invalidate()
        systemMonitorInterval = interval
        systemVolumeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pollSystemVolume()
            }
        }
        pollSystemVolume()
    }

    private func stopSystemVolumeMonitoring() {
        systemVolumeTimer?.invalidate()
        systemVolumeTimer = nil
    }

    private func updateSystemVolumeMonitoringState() {
        // Keep a lightweight monitor always to detect output-device changes.
        let targetInterval: TimeInterval = (dynamicCompensationEnabled || strictVolumeNormalizationEnabled) ? 0.6 : 1.4
        if systemVolumeTimer == nil || abs(systemMonitorInterval - targetInterval) > 0.001 {
            startSystemVolumeMonitoring(interval: targetInterval)
        }
    }

    private func pollSystemVolume() {
        if systemPollInFlight { return }
        systemPollInFlight = true
        systemMonitorQueue.async { [weak self] in
            let scalar = Self.readSystemOutputVolume()
            let deviceID = Self.readDefaultOutputDeviceID() ?? 0
            let deviceUID = deviceID != 0 ? (Self.readOutputDeviceUID(deviceID) ?? "") : ""
            let deviceName = deviceID != 0 ? (Self.readOutputDeviceName(deviceID) ?? "Системное устройство") : "Системное устройство"

            Task { @MainActor [weak self] in
                guard let self else { return }
                defer { self.systemPollInFlight = false }

                self.detectedSystemVolumeAvailable = scalar != nil
                if let scalar {
                    self.detectedSystemVolumePercent = scalar * 100.0
                }

                let nextVolume = scalar ?? self.lastSystemVolume
                let volumeChanged = abs(self.lastSystemVolume - nextVolume) > 0.005
                if volumeChanged {
                    self.lastSystemVolume = nextVolume
                }

                let deviceChanged = deviceID != self.lastOutputDeviceID || deviceUID != self.currentOutputDeviceUID
                if deviceChanged {
                    self.lastOutputDeviceID = deviceID
                    self.currentOutputDeviceUID = deviceUID
                    self.currentOutputDeviceName = deviceName
                    self.currentOutputDeviceBoost = self.outputDeviceBoosts[deviceUID] ?? 1.0
                    self.soundEngine.handleOutputDeviceChanged()
                }

                if volumeChanged || deviceChanged {
                    self.updateDynamicCompensation()
                }
            }
        }
    }

    private func updateDynamicCompensation() {
        var gain: Double
        if strictVolumeNormalizationEnabled {
            gain = Self.autoInverseGain(
                systemVolumeScalar: lastSystemVolume,
                targetAt100: autoNormalizeTargetAt100
            )
        } else {
            gain = Self.curveGain(
                systemVolume: lastSystemVolume,
                macLow: levelMacLow,
                kbdLow: levelKbdLow,
                macMid: levelMacMid,
                kbdMid: levelKbdMid,
                macHigh: levelMacHigh,
                kbdHigh: levelKbdHigh
            )
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

    func autoInverseGainPreview(systemVolumePercent: Double) -> Double {
        let normalized = (systemVolumePercent / 100.0).clamped(to: 0.0 ... 1.0)
        return Self.autoInverseGain(
            systemVolumeScalar: normalized,
            targetAt100: autoNormalizeTargetAt100
        )
    }

    nonisolated private static func autoInverseGain(systemVolumeScalar: Double, targetAt100: Double) -> Double {
        // macOS volume slider uses an audio-taper curve; compensate in the same domain.
        let scalar = systemVolumeScalar.clamped(to: 0.05 ... 1.0)
        let effective = pow(scalar, 2.2).clamped(to: 0.003 ... 1.0)
        let target = targetAt100.clamped(to: 0.20 ... 1.20)
        return (target / effective).clamped(to: 0.20 ... 12.0)
    }

    nonisolated private static func curveGain(
        systemVolume: Double,
        macLow: Double,
        kbdLow: Double,
        macMid: Double,
        kbdMid: Double,
        macHigh: Double,
        kbdHigh: Double
    ) -> Double {
        let v = systemVolume.clamped(to: 0.0 ... 1.0)
        let points: [(x: Double, y: Double)] = [
            (macLow.clamped(to: 0.05 ... 0.90), kbdLow.clamped(to: 0.20 ... 4.00)),
            (macMid.clamped(to: 0.05 ... 0.95), kbdMid.clamped(to: 0.20 ... 4.00)),
            (macHigh.clamped(to: 0.10 ... 1.00), kbdHigh.clamped(to: 0.20 ... 4.00))
        ].sorted { $0.x < $1.x }

        let p0 = points[0]
        let p1 = points[1]
        let p2 = points[2]

        if v <= p0.x { return p0.y }
        if v <= p1.x {
            let t = (v - p0.x) / max(0.0001, p1.x - p0.x)
            return p0.y + (p1.y - p0.y) * t
        }
        if v <= p2.x {
            let t = (v - p1.x) / max(0.0001, p2.x - p1.x)
            return p1.y + (p2.y - p1.y) * t
        }
        return p2.y
    }

    private func trackTypingHit() {
        let now = CFAbsoluteTimeGetCurrent()
        typingTimestamps.append(now)
        recomputeTypingSpeed(now: now)
        updateTypingAdaptation()
    }

    private func startTypingDecayMonitoring() {
        typingDecayTimer?.invalidate()
        typingDecayTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let now = CFAbsoluteTimeGetCurrent()
                self.recomputeTypingSpeed(now: now)
                self.updateTypingAdaptation()
            }
        }
    }

    private func stopTypingDecayMonitoring() {
        typingDecayTimer?.invalidate()
        typingDecayTimer = nil
    }

    private func updateTypingDecayMonitoringState() {
        if typingAdaptiveEnabled && !strictVolumeNormalizationEnabled {
            if typingDecayTimer == nil {
                startTypingDecayMonitoring()
            }
        } else {
            stopTypingDecayMonitoring()
        }
    }

    private func recomputeTypingSpeed(now: CFAbsoluteTime) {
        let windowStart = now - 3.0
        typingTimestamps.removeAll { $0 < windowStart }
        let cps = Double(typingTimestamps.count) / 3.0
        if abs(typingCPS - cps) > 0.03 {
            typingCPS = cps
        }
        let wpm = cps * 12.0
        if abs(typingWPM - wpm) > 0.4 {
            typingWPM = wpm
        }
        personalBaselineCPS = personalBaselineCPS * 0.985 + cps * 0.015
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
        let target = max(2.5, personalBaselineCPS * 1.1)
        let normalized = (typingCPS / target).clamped(to: 0.0 ... 1.6)
        let gain = 1.0 + 0.25 + normalized * 0.95
        let clamped = gain.clamped(to: 1.0 ... 2.5)
        soundEngine.typingSpeedGain = Float(clamped)
        if abs(liveTypingGain - clamped) > 0.005 {
            liveTypingGain = clamped
        }
    }

    private func saveCurrentDeviceBoost() {
        guard !currentOutputDeviceUID.isEmpty else { return }
        outputDeviceBoosts[currentOutputDeviceUID] = currentOutputDeviceBoost.clamped(to: 0.5 ... 2.0)
        if let data = try? JSONEncoder().encode(outputDeviceBoosts) {
            defaults.set(data, forKey: Keys.outputDeviceBoosts)
        }
    }

    nonisolated private static func readSystemOutputVolume() -> Double? {
        guard let deviceID = readDefaultOutputDeviceID() else { return nil }
        return readDeviceVolumeScalar(deviceID)
    }

    nonisolated private static func readDeviceVolumeScalar(_ deviceID: AudioObjectID) -> Double? {
        func readScalar(selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope, element: AudioObjectPropertyElement) -> Double? {
            var address = AudioObjectPropertyAddress(
                mSelector: selector,
                mScope: scope,
                mElement: element
            )
            guard AudioObjectHasProperty(deviceID, &address) else { return nil }
            var volume = Float32(0)
            var size = UInt32(MemoryLayout<Float32>.size)
            let status = AudioObjectGetPropertyData(
                deviceID,
                &address,
                0,
                nil,
                &size,
                &volume
            )
            guard status == noErr else { return nil }
            return Double(volume).clamped(to: 0.0 ... 1.0)
        }

        let attempts: [(AudioObjectPropertySelector, AudioObjectPropertyScope, AudioObjectPropertyElement)] = [
            (kAudioHardwareServiceDeviceProperty_VirtualMainVolume, kAudioDevicePropertyScopeOutput, kAudioObjectPropertyElementMain),
            (kAudioHardwareServiceDeviceProperty_VirtualMainVolume, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMain),
            (kAudioDevicePropertyVolumeScalar, kAudioDevicePropertyScopeOutput, kAudioObjectPropertyElementMain),
            (kAudioDevicePropertyVolumeScalar, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMain)
        ]
        for (selector, scope, element) in attempts {
            if let value = readScalar(selector: selector, scope: scope, element: element) {
                return value
            }
        }

        // Some devices expose per-channel volume only.
        let channels: [UInt32] = [1, 2]
        var values: [Double] = []
        for channel in channels {
            if let value = readScalar(
                selector: kAudioDevicePropertyVolumeScalar,
                scope: kAudioDevicePropertyScopeOutput,
                element: channel
            ) {
                values.append(value)
            } else if let value = readScalar(
                selector: kAudioDevicePropertyVolumeScalar,
                scope: kAudioObjectPropertyScopeGlobal,
                element: channel
            ) {
                values.append(value)
            }
        }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    nonisolated private static func readDefaultOutputDeviceID() -> AudioObjectID? {
        var deviceID = AudioObjectID(0)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        return (status == noErr && deviceID != 0) ? deviceID : nil
    }

    nonisolated private static func readOutputDeviceUID(_ deviceID: AudioObjectID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var cfUID: CFString?
        var size = UInt32(MemoryLayout<CFString?>.size)
        let status = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &size,
            &cfUID
        )
        guard status == noErr, let cfUID else { return nil }
        return cfUID as String
    }

    nonisolated private static func readOutputDeviceName(_ deviceID: AudioObjectID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var cfName: CFString?
        var size = UInt32(MemoryLayout<CFString?>.size)
        let status = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &size,
            &cfName
        )
        guard status == noErr, let cfName else { return nil }
        return cfName as String
    }

    nonisolated private func runTCCReset(service: String, bundleID: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        process.arguments = ["reset", service, bundleID]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            NSLog("Failed to reset TCC \(service): \(error)")
        }
    }

    nonisolated private static func preflightInputMonitoring(promptIfNeeded: Bool) -> Bool {
        let preflight = CGPreflightListenEventAccess()
        if preflight || !promptIfNeeded {
            return preflight
        }
        return CGRequestListenEventAccess()
    }
}

private struct SettingsSnapshot: Codable {
    let profile: String
    let volume: Double
    let variation: Double
    let playKeyUp: Bool
    let pressLevel: Double
    let releaseLevel: Double
    let spaceLevel: Double
}

enum KeyEventType {
    case down
    case up
}

final class GlobalKeyEventTap {
    var onEvent: ((KeyEventType, Int, Bool) -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var globalMonitor: Any?
    private var firstEventLogged = false

    func start() -> Bool {
        if eventTap != nil || globalMonitor != nil { return true }
        firstEventLogged = false

        let mask = (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            _ = proxy
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let instance = Unmanaged<GlobalKeyEventTap>.fromOpaque(refcon).takeUnretainedValue()

            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if let tap = instance.eventTap {
                    CGEvent.tapEnable(tap: tap, enable: true)
                }
                return Unmanaged.passUnretained(event)
            }

            let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
            let isAutorepeat = event.getIntegerValueField(.keyboardEventAutorepeat) == 1

            if type == .keyDown || type == .keyUp {
                if !instance.firstEventLogged {
                    instance.firstEventLogged = true
                    NSLog("Keyboard events are flowing via CGEvent tap (first event keyCode=\(keyCode), type=\(type.rawValue))")
                }
                DispatchQueue.main.async {
                    instance.onEvent?(type == .keyDown ? .down : .up, keyCode, isAutorepeat)
                }
                return Unmanaged.passUnretained(event)
            }

            if type == .flagsChanged {
                guard let modifierEvent = instance.modifierEventType(for: keyCode, flags: event.flags) else {
                    return Unmanaged.passUnretained(event)
                }
                DispatchQueue.main.async {
                    instance.onEvent?(modifierEvent, keyCode, false)
                }
            }

            return Unmanaged.passUnretained(event)
        }

        let ref = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: ref
        ) else {
            NSLog("CGEvent tap creation failed. Trying NSEvent global monitor fallback.")
            return startGlobalMonitorFallback()
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFMachPortSetInvalidationCallBack(tap) { _, _ in }

        eventTap = tap
        runLoopSource = source

        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        NSLog("Using CGEvent tap keyboard capture")
        return true
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let tap = eventTap {
            CFMachPortInvalidate(tap)
        }
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
        }
        runLoopSource = nil
        eventTap = nil
        globalMonitor = nil
    }

    private func startGlobalMonitorFallback() -> Bool {
        let monitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.keyDown, .keyUp, .flagsChanged]
        ) { [weak self] event in
            guard let self else { return }
            switch event.type {
            case .keyDown:
                if !self.firstEventLogged {
                    self.firstEventLogged = true
                    NSLog("Keyboard events are flowing via NSEvent global monitor (first keyDown keyCode=\(event.keyCode))")
                }
                self.onEvent?(.down, Int(event.keyCode), event.isARepeat)
            case .keyUp:
                self.onEvent?(.up, Int(event.keyCode), false)
            case .flagsChanged:
                let flags = CGEventFlags(rawValue: UInt64(event.modifierFlags.rawValue))
                guard let modifierEvent = self.modifierEventType(for: Int(event.keyCode), flags: flags) else {
                    return
                }
                self.onEvent?(modifierEvent, Int(event.keyCode), false)
            default:
                return
            }
        }

        guard let monitor else {
            NSLog("Global keyboard monitor fallback failed to start")
            return false
        }
        globalMonitor = monitor
        NSLog("Using NSEvent global keyboard monitor fallback")
        return true
    }

    private func modifierEventType(for keyCode: Int, flags: CGEventFlags) -> KeyEventType? {
        let isDown: Bool
        switch keyCode {
        case 55, 54:
            isDown = flags.contains(.maskCommand)
        case 58, 61:
            isDown = flags.contains(.maskAlternate)
        case 59, 62:
            isDown = flags.contains(.maskControl)
        case 56, 60:
            isDown = flags.contains(.maskShift)
        case 57:
            isDown = flags.contains(.maskAlphaShift)
        default:
            return nil
        }
        return isDown ? .down : .up
    }
}

enum SoundProfile: String, CaseIterable, Identifiable {
    case customPack
    case kalihBoxWhite
    case mechvibesGateronBrownsRevolt
    case mechvibesHyperXAqua
    case mechvibesBoxJade
    case mechvibesOperaGX

    var id: String { rawValue }

    var title: String {
        switch self {
        case .customPack: return "Custom Pack"
        case .kalihBoxWhite: return "Kalih Box White"
        case .mechvibesGateronBrownsRevolt: return "Mechvibes: Gateron Browns - Revolt"
        case .mechvibesHyperXAqua: return "Mechvibes: HyperX Aqua"
        case .mechvibesBoxJade: return "Mechvibes: Box Jade"
        case .mechvibesOperaGX: return "Mechvibes: Opera GX"
        }
    }
}

final class ClickSoundEngine {
    private var engine = AVAudioEngine()
    private var player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 2)!

    var masterVolume: Float = 0.75
    var variation: Float = 0.3
    var pressLevel: Float = 1.0
    var releaseLevel: Float = 0.65
    var spaceLevel: Float = 1.1
    var dynamicCompensationGain: Float = 1.0
    var typingSpeedGain: Float = 1.0
    var strictLevelingEnabled: Bool = false
    var stackModeEnabled: Bool = false
    var stackDensity: Float = 0.55
    var limiterEnabled: Bool = true
    var limiterDrive: Float = 1.2
    private var lastDownHitTime: CFAbsoluteTime = 0

    private struct SampleBank {
        var keyDown: [AVAudioPCMBuffer]
        var keyUp: [AVAudioPCMBuffer]
        var spaceDown: [AVAudioPCMBuffer]
        var spaceUp: [AVAudioPCMBuffer]
        var enterDown: [AVAudioPCMBuffer]
        var enterUp: [AVAudioPCMBuffer]
        var backspaceDown: [AVAudioPCMBuffer]
        var backspaceUp: [AVAudioPCMBuffer]
    }

    private var bank = SampleBank(
        keyDown: [],
        keyUp: [],
        spaceDown: [],
        spaceUp: [],
        enterDown: [],
        enterUp: [],
        backspaceDown: [],
        backspaceUp: []
    )
    private var customPackRoot: URL?
    private enum SampleGroup: Hashable {
        case keyDown, keyUp
        case spaceDown, spaceUp
        case enterDown, enterUp
        case backspaceDown, backspaceUp
    }
    private var lastSampleIndexByGroup: [SampleGroup: Int] = [:]
    private var lastOutputDeviceReinit: CFAbsoluteTime = 0
    private let scheduleLock = NSLock()
    private var estimatedPlaybackEndTime: CFAbsoluteTime = 0

    init() {
        rebuildAudioGraph()
    }

    func setProfile(_ profile: SoundProfile) {
        switch profile {
        case .customPack:
            if let root = customPackRoot, installCustomPack(from: root) {
                return
            }
            let fallback = Self.defaultCustomPackDirectory()
            if installCustomPack(from: fallback) {
                return
            }
            bank = loadBank(
                keyDown: ["Sounds/kalihboxwhite/kalihboxwhite-press_key1.mp3"],
                keyUp: ["Sounds/kalihboxwhite/kalihboxwhite-release_key.mp3"],
                spaceDown: ["Sounds/kalihboxwhite/kalihboxwhite-press_space.mp3"],
                spaceUp: ["Sounds/kalihboxwhite/kalihboxwhite-release_space.mp3"],
                enterDown: ["Sounds/kalihboxwhite/kalihboxwhite-press_enter.mp3"],
                enterUp: ["Sounds/kalihboxwhite/kalihboxwhite-release_enter.mp3"],
                backspaceDown: ["Sounds/kalihboxwhite/kalihboxwhite-press_back.mp3"],
                backspaceUp: ["Sounds/kalihboxwhite/kalihboxwhite-release_back.mp3"]
            )
        case .kalihBoxWhite:
            bank = loadBank(
                keyDown: [
                    "Sounds/kalihboxwhite/kalihboxwhite-press_key1.mp3",
                    "Sounds/kalihboxwhite/kalihboxwhite-press_key2.mp3",
                    "Sounds/kalihboxwhite/kalihboxwhite-press_key3.mp3",
                    "Sounds/kalihboxwhite/kalihboxwhite-press_key4.mp3",
                    "Sounds/kalihboxwhite/kalihboxwhite-press_key5.mp3",
                    "Sounds/kalihboxwhite/kalihboxwhite-press_key6.mp3",
                    "Sounds/kalihboxwhite/kalihboxwhite-press_key7.mp3",
                    "Sounds/kalihboxwhite/kalihboxwhite-press_key8.mp3",
                    "Sounds/kalihboxwhite/kalihboxwhite-press_key9.mp3",
                    "Sounds/kalihboxwhite/kalihboxwhite-press_key10.mp3"
                ],
                keyUp: ["Sounds/kalihboxwhite/kalihboxwhite-release_key.mp3"],
                spaceDown: ["Sounds/kalihboxwhite/kalihboxwhite-press_space.mp3"],
                spaceUp: ["Sounds/kalihboxwhite/kalihboxwhite-release_space.mp3"],
                enterDown: ["Sounds/kalihboxwhite/kalihboxwhite-press_enter.mp3"],
                enterUp: ["Sounds/kalihboxwhite/kalihboxwhite-release_enter.mp3"],
                backspaceDown: ["Sounds/kalihboxwhite/kalihboxwhite-press_back.mp3"],
                backspaceUp: ["Sounds/kalihboxwhite/kalihboxwhite-release_back.mp3"]
            )
        case .mechvibesGateronBrownsRevolt:
            bank = loadBankFromMechvibesConfig(
                resourceDirectory: "Sounds/mv-gateron-browns-revolt",
                configFilename: "config-gateron-browns-revolt.json"
            )
        case .mechvibesHyperXAqua:
            bank = loadBankFromMechvibesConfig(
                resourceDirectory: "Sounds/mv-hyperx-aqua",
                configFilename: "config-hyperx-aqua.json"
            )
        case .mechvibesBoxJade:
            bank = loadBankFromMechvibesConfig(
                resourceDirectory: "Sounds/mv-boxjade",
                configFilename: "config-boxjade.json"
            )
        case .mechvibesOperaGX:
            bank = loadBankFromMechvibesConfig(
                resourceDirectory: "Sounds/mv-opera-gx",
                configFilename: "config-opera-gx.json"
            )
        }
    }

    func installCustomPack(from root: URL) -> Bool {
        let resolvedRoot = Self.resolveRoot(for: root)
        let loaded = loadBankFromDirectory(resolvedRoot)
        guard !loaded.keyDown.isEmpty else { return false }
        customPackRoot = resolvedRoot
        bank = loaded
        return true
    }

    func startIfNeeded() {
        if !engine.isRunning {
            do {
                engine.mainMixerNode.outputVolume = 1.0
                try engine.start()
                player.play()
            } catch {
                NSLog("Audio engine start failed: \(error)")
            }
        }
    }

    func stop() {
        player.stop()
        engine.stop()
        scheduleLock.lock()
        estimatedPlaybackEndTime = 0
        scheduleLock.unlock()
    }

    func handleOutputDeviceChanged() {
        let wasRunning = engine.isRunning
        let now = CFAbsoluteTimeGetCurrent()
        // Debounce noisy route notifications.
        if now - lastOutputDeviceReinit < 0.45 { return }
        lastOutputDeviceReinit = now

        rebuildAudioGraph()
        if wasRunning {
            startIfNeeded()
        }
        NSLog("Audio engine graph rebuilt after output-device change")
    }

    private func rebuildAudioGraph() {
        let newEngine = AVAudioEngine()
        let newPlayer = AVAudioPlayerNode()
        newEngine.attach(newPlayer)
        newEngine.connect(newPlayer, to: newEngine.mainMixerNode, format: format)
        newEngine.mainMixerNode.outputVolume = 1.0
        engine = newEngine
        player = newPlayer
        scheduleLock.lock()
        estimatedPlaybackEndTime = 0
        scheduleLock.unlock()
    }

    func playDown(for keyCode: Int, autorepeat: Bool) {
        guard engine.isRunning else { return }

        let pool: [AVAudioPCMBuffer]
        let group: SampleGroup
        let keyLevel: Float
        switch keyCode {
        case 49:
            pool = bank.spaceDown
            group = .spaceDown
            keyLevel = spaceLevel
        case 36, 76:
            pool = bank.enterDown
            group = .enterDown
            keyLevel = (pressLevel + spaceLevel) * 0.5
        case 51, 117:
            pool = bank.backspaceDown
            group = .backspaceDown
            keyLevel = pressLevel * 0.95
        default:
            pool = bank.keyDown
            group = .keyDown
            keyLevel = pressLevel
        }

        let effectiveVariation = max(0.10, variation)
        let jitterScale: Float = strictLevelingEnabled ? 0.04 : 0.34
        var gainJitter = Float.random(in: -effectiveVariation ... effectiveVariation) * jitterScale
        if autorepeat { gainJitter -= 0.1 }
        var gain = (masterVolume * keyLevel * dynamicCompensationGain * typingSpeedGain + gainJitter).clamped(to: 0.03 ... 16.0)
        var interrupt = false
        if stackModeEnabled && !strictLevelingEnabled {
            let now = CFAbsoluteTimeGetCurrent()
            let dt = now - lastDownHitTime
            lastDownHitTime = now
            let density = stackDensity.clamped(to: 0.0 ... 1.0)
            let proximity = Float(max(0.0, 1.0 - dt / 0.18))
            let stackBoost = 1.0 + (density * density) * proximity * 3.2
            gain = (gain * stackBoost).clamped(to: 0.03 ... 18.0)
            interrupt = density > 0.25
        }
        schedule(pickSample(from: pool, group: group), gain: gain, interruptIfNeeded: interrupt)
    }

    func playUp(for keyCode: Int) {
        guard engine.isRunning else { return }
        if stackModeEnabled && !strictLevelingEnabled {
            let density = stackDensity.clamped(to: 0.0 ... 1.0)
            if density >= 0.65 {
                return
            }
            // In stack mode, aggressively trim release tails at high density.
            let keepProbability = (1.0 - density).clamped(to: 0.02 ... 1.0)
            if Float.random(in: 0 ... 1) > keepProbability {
                return
            }
        }
        let pool: [AVAudioPCMBuffer]
        let group: SampleGroup
        switch keyCode {
        case 49:
            pool = bank.spaceUp
            group = .spaceUp
        case 36, 76:
            pool = bank.enterUp
            group = .enterUp
        case 51, 117:
            pool = bank.backspaceUp
            group = .backspaceUp
        default:
            pool = bank.keyUp
            group = .keyUp
        }
        let effectiveVariation = max(0.10, variation)
        let releaseJitterScale: Float = strictLevelingEnabled ? 0.02 : 0.16
        var gain = (masterVolume * releaseLevel * dynamicCompensationGain * typingSpeedGain + Float.random(in: -effectiveVariation ... effectiveVariation) * releaseJitterScale).clamped(to: 0.02 ... 8.0)
        if stackModeEnabled && !strictLevelingEnabled {
            let tailCut = (1.0 - stackDensity * 0.9).clamped(to: 0.08 ... 1.0)
            gain = (gain * tailCut).clamped(to: 0.01 ... 1.3)
        }
        let interrupt = !strictLevelingEnabled && stackModeEnabled && stackDensity > 0.25
        schedule(pickSample(from: pool, group: group), gain: gain, interruptIfNeeded: interrupt)
    }

    private func schedule(_ buffer: AVAudioPCMBuffer?, gain: Float, interruptIfNeeded: Bool) {
        guard let buffer else { return }
        // Duplicate buffer with per-hit gain for low-latency playback without re-synthesis.
        guard let copy = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: buffer.frameCapacity) else { return }
        copy.frameLength = buffer.frameLength

        let channels = Int(format.channelCount)
        let frames = Int(buffer.frameLength)
        let panJitter = Float.random(in: -1 ... 1) * variation * 0.14
        for channel in 0 ..< channels {
            guard let src = buffer.floatChannelData?[channel],
                  let dst = copy.floatChannelData?[channel] else { continue }
            let channelPanGain: Float
            if channels >= 2 {
                channelPanGain = channel == 0 ? (1.0 - max(0, panJitter)) : (1.0 + min(0, panJitter))
            } else {
                channelPanGain = 1.0
            }
            for i in 0 ..< frames {
                let pre = src[i] * gain * channelPanGain
                if limiterEnabled {
                    // Audible drive control in normal typing:
                    // blend clean signal with driven soft-clip curve.
                    let drive = max(0.6, limiterDrive)
                    let shaped = Float(tanh(Double(pre * drive)) / tanh(Double(drive)))
                    let mix = ((drive - 0.6) / 1.4).clamped(to: 0.0 ... 1.0)
                    dst[i] = pre * (1 - mix) + shaped * mix
                } else {
                    dst[i] = pre.clamped(to: -1.0 ... 1.0)
                }
            }
        }

        let now = CFAbsoluteTimeGetCurrent()
        let bufferSeconds = Double(copy.frameLength) / format.sampleRate
        var queueOverflowInterrupt = false
        scheduleLock.lock()
        if !player.isPlaying || estimatedPlaybackEndTime < now - 0.45 {
            estimatedPlaybackEndTime = now
        }
        let queuedAhead = max(0, estimatedPlaybackEndTime - now)
        let queueLimit = strictLevelingEnabled ? 0.05 : 0.12
        if queuedAhead > queueLimit {
            queueOverflowInterrupt = true
            estimatedPlaybackEndTime = now + bufferSeconds
        } else {
            let start = max(now, estimatedPlaybackEndTime)
            estimatedPlaybackEndTime = start + bufferSeconds
        }
        scheduleLock.unlock()

        // Interrupt when queue starts to lag behind live typing.
        let shouldInterrupt = interruptIfNeeded || queueOverflowInterrupt
        let options: AVAudioPlayerNodeBufferOptions = shouldInterrupt ? [.interrupts] : []
        player.scheduleBuffer(copy, at: nil, options: options, completionHandler: nil)
        if !player.isPlaying {
            player.play()
        }
    }

    private func pickSample(from pool: [AVAudioPCMBuffer], group: SampleGroup) -> AVAudioPCMBuffer? {
        guard !pool.isEmpty else { return nil }
        if pool.count == 1 {
            lastSampleIndexByGroup[group] = 0
            return pool[0]
        }

        let previous = lastSampleIndexByGroup[group]
        var idx = Int.random(in: 0 ..< pool.count)
        if let previous {
            var guardCounter = 0
            while idx == previous && guardCounter < 4 {
                idx = Int.random(in: 0 ..< pool.count)
                guardCounter += 1
            }
        }
        lastSampleIndexByGroup[group] = idx
        return pool[idx]
    }

    private func loadBank(
        keyDown: [String],
        keyUp: [String],
        spaceDown: [String],
        spaceUp: [String],
        enterDown: [String],
        enterUp: [String],
        backspaceDown: [String],
        backspaceUp: [String]
    ) -> SampleBank {
        let variantCount = 2
        let loaded = SampleBank(
            keyDown: expandSamples(keyDown.compactMap(loadPCMBuffer(resourcePath:)), variantsPerSample: variantCount),
            keyUp: expandSamples(keyUp.compactMap(loadPCMBuffer(resourcePath:)), variantsPerSample: variantCount),
            spaceDown: expandSamples(spaceDown.compactMap(loadPCMBuffer(resourcePath:)), variantsPerSample: variantCount),
            spaceUp: expandSamples(spaceUp.compactMap(loadPCMBuffer(resourcePath:)), variantsPerSample: variantCount),
            enterDown: expandSamples(enterDown.compactMap(loadPCMBuffer(resourcePath:)), variantsPerSample: variantCount),
            enterUp: expandSamples(enterUp.compactMap(loadPCMBuffer(resourcePath:)), variantsPerSample: variantCount),
            backspaceDown: expandSamples(backspaceDown.compactMap(loadPCMBuffer(resourcePath:)), variantsPerSample: variantCount),
            backspaceUp: expandSamples(backspaceUp.compactMap(loadPCMBuffer(resourcePath:)), variantsPerSample: variantCount)
        )

        guard !loaded.keyDown.isEmpty else {
            NSLog("No keyboard sample files loaded for selected profile")
            return bank
        }
        return loaded
    }

    private func loadBankFromDirectory(_ root: URL) -> SampleBank {
        let exts = ["wav", "mp3", "m4a", "aif", "aiff"]
        func files(prefixes: [String]) -> [URL] {
            guard let all = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else { return [] }
            let lower = all.map { $0 }.filter { exts.contains($0.pathExtension.lowercased()) }
            let matched = lower.filter { url in
                let name = url.deletingPathExtension().lastPathComponent.lowercased()
                return prefixes.contains { name.hasPrefix($0) }
            }.sorted { $0.lastPathComponent < $1.lastPathComponent }
            return matched
        }

        let loaded = SampleBank(
            keyDown: expandSamples(files(prefixes: ["key-down", "press-key", "keydown"]).compactMap(loadPCMBuffer(fileURL:)), variantsPerSample: 2),
            keyUp: expandSamples(files(prefixes: ["key-up", "release-key", "keyup"]).compactMap(loadPCMBuffer(fileURL:)), variantsPerSample: 2),
            spaceDown: expandSamples(files(prefixes: ["space-down", "press-space"]).compactMap(loadPCMBuffer(fileURL:)), variantsPerSample: 2),
            spaceUp: expandSamples(files(prefixes: ["space-up", "release-space"]).compactMap(loadPCMBuffer(fileURL:)), variantsPerSample: 2),
            enterDown: expandSamples(files(prefixes: ["enter-down", "press-enter"]).compactMap(loadPCMBuffer(fileURL:)), variantsPerSample: 2),
            enterUp: expandSamples(files(prefixes: ["enter-up", "release-enter"]).compactMap(loadPCMBuffer(fileURL:)), variantsPerSample: 2),
            backspaceDown: expandSamples(files(prefixes: ["backspace-down", "press-back"]).compactMap(loadPCMBuffer(fileURL:)), variantsPerSample: 2),
            backspaceUp: expandSamples(files(prefixes: ["backspace-up", "release-back"]).compactMap(loadPCMBuffer(fileURL:)), variantsPerSample: 2)
        )
        return loaded
    }

    private enum MechvibesDefineValue: Decodable {
        case file(String)
        case sprite([Double])
        case none

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if container.decodeNil() {
                self = .none
                return
            }
            if let file = try? container.decode(String.self) {
                self = .file(file)
                return
            }
            if let sprite = try? container.decode([Double].self) {
                self = .sprite(sprite)
                return
            }
            self = .none
        }
    }

    private struct MechvibesConfig: Decodable {
        let sound: String?
        let key_define_type: String?
        let defines: [String: MechvibesDefineValue]
    }

    private func loadBankFromMechvibesConfig(resourceDirectory: String, configFilename: String) -> SampleBank {
        let configPath = "\(resourceDirectory)/\(configFilename)"
        guard let configURL = resolveResourceURL(path: configPath) else {
            NSLog("Missing Mechvibes config: \(configPath)")
            return bank
        }

        let config: MechvibesConfig
        do {
            let data = try Data(contentsOf: configURL)
            config = try JSONDecoder().decode(MechvibesConfig.self, from: data)
        } catch {
            NSLog("Failed to decode Mechvibes config \(configPath): \(error)")
            return bank
        }

        let isMulti = (config.key_define_type ?? "single") == "multi"

        func stringFile(for keyCode: Int) -> String? {
            guard let value = config.defines[String(keyCode)] else { return nil }
            if case let .file(file) = value, !file.isEmpty { return file }
            return nil
        }

        var keyDownFiles: [String] = []
        if isMulti {
            let allFiles = config.defines.values.compactMap { value -> String? in
                if case let .file(file) = value, !file.isEmpty { return file }
                return nil
            }
            keyDownFiles = Array(Set(allFiles)).sorted()
        } else if let sound = config.sound, !sound.isEmpty {
            keyDownFiles = [sound]
        }

        let fallback = keyDownFiles.first
        let spaceFile = stringFile(for: 57) ?? fallback
        let enterFile = stringFile(for: 28) ?? fallback
        let backspaceFile = stringFile(for: 14) ?? fallback

        func prefixed(_ file: String?) -> [String] {
            guard let file, !file.isEmpty else { return [] }
            return ["\(resourceDirectory)/\(file)"]
        }

        let raw = loadBank(
            keyDown: keyDownFiles.map { "\(resourceDirectory)/\($0)" },
            // Many Mechvibes packs don't ship dedicated key-up files.
            // Reuse key-down files to avoid "half-silent" typing feel on key release.
            keyUp: keyDownFiles.map { "\(resourceDirectory)/\($0)" },
            spaceDown: prefixed(spaceFile),
            spaceUp: prefixed(spaceFile),
            enterDown: prefixed(enterFile),
            enterUp: prefixed(enterFile),
            backspaceDown: prefixed(backspaceFile),
            backspaceUp: prefixed(backspaceFile)
        )
        return boostedIfQuiet(raw)
    }

    private func boostedIfQuiet(_ bank: SampleBank) -> SampleBank {
        let measuredPeak = max(
            peak(of: bank.keyDown),
            peak(of: bank.spaceDown),
            peak(of: bank.enterDown),
            peak(of: bank.backspaceDown)
        )
        guard measuredPeak > 0 else { return bank }
        let targetPeak: Float = 0.78
        let gain = (targetPeak / measuredPeak).clamped(to: 1.0 ... 5.0)
        if gain <= 1.05 { return bank }
        NSLog("Boosting quiet sound pack by x\(String(format: "%.2f", gain)) (peak=\(String(format: "%.3f", measuredPeak)))")
        return SampleBank(
            keyDown: applyGain(bank.keyDown, gain: gain),
            keyUp: applyGain(bank.keyUp, gain: gain),
            spaceDown: applyGain(bank.spaceDown, gain: gain),
            spaceUp: applyGain(bank.spaceUp, gain: gain),
            enterDown: applyGain(bank.enterDown, gain: gain),
            enterUp: applyGain(bank.enterUp, gain: gain),
            backspaceDown: applyGain(bank.backspaceDown, gain: gain),
            backspaceUp: applyGain(bank.backspaceUp, gain: gain)
        )
    }

    private func peak(of buffers: [AVAudioPCMBuffer]) -> Float {
        var m: Float = 0
        for buffer in buffers {
            let frames = Int(buffer.frameLength)
            let channels = Int(buffer.format.channelCount)
            for ch in 0 ..< channels {
                guard let data = buffer.floatChannelData?[ch] else { continue }
                for i in 0 ..< frames {
                    m = max(m, abs(data[i]))
                }
            }
        }
        return m
    }

    private func applyGain(_ buffers: [AVAudioPCMBuffer], gain: Float) -> [AVAudioPCMBuffer] {
        buffers.compactMap { buffer in
            guard let out = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: buffer.frameCapacity) else { return nil }
            out.frameLength = buffer.frameLength
            let frames = Int(buffer.frameLength)
            let channels = Int(format.channelCount)
            for ch in 0 ..< channels {
                guard let src = buffer.floatChannelData?[ch],
                      let dst = out.floatChannelData?[ch] else { continue }
                for i in 0 ..< frames {
                    dst[i] = (src[i] * gain).clamped(to: -1.0 ... 1.0)
                }
            }
            return out
        }
    }

    private func expandSamples(_ source: [AVAudioPCMBuffer], variantsPerSample: Int) -> [AVAudioPCMBuffer] {
        guard !source.isEmpty else { return [] }
        var out: [AVAudioPCMBuffer] = []
        for base in source {
            out.append(base)
            for _ in 0 ..< variantsPerSample {
                if let v = makeVariant(from: base) {
                    out.append(v)
                }
            }
        }
        return out
    }

    private func makeVariant(from base: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        let rateJitter = Double.random(in: -0.04 ... 0.04)
        let rate = max(0.9, min(1.1, 1.0 + rateJitter))
        let transient = Float.random(in: 0.92 ... 1.08)
        let tail = Float.random(in: 0.94 ... 1.04)
        return resample(buffer: base, rate: rate, transient: transient, tail: tail)
    }

    private func resample(buffer: AVAudioPCMBuffer, rate: Double, transient: Float, tail: Float) -> AVAudioPCMBuffer? {
        let frames = Int(buffer.frameLength)
        guard frames > 1 else { return nil }
        guard let out = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: buffer.frameCapacity) else { return nil }
        out.frameLength = buffer.frameLength

        let channels = Int(format.channelCount)
        for ch in 0 ..< channels {
            guard let src = buffer.floatChannelData?[ch],
                  let dst = out.floatChannelData?[ch] else { continue }
            for i in 0 ..< frames {
                let pos = Double(i) * rate
                let i0 = min(frames - 1, Int(pos))
                let i1 = min(frames - 1, i0 + 1)
                let frac = Float(pos - Double(i0))
                let sample = src[i0] * (1 - frac) + src[i1] * frac
                let t = Float(i) / Float(frames)
                let shape = (t < 0.25 ? transient : tail)
                dst[i] = sample * shape
            }
        }
        return out
    }

    private func loadPCMBuffer(resourcePath: String) -> AVAudioPCMBuffer? {
        guard let url = resolveResourceURL(path: resourcePath) else {
            NSLog("Missing audio resource: \(resourcePath)")
            return nil
        }

        do {
            let file = try AVAudioFile(forReading: url)
            let inFormat = file.processingFormat
            guard let sourceBuffer = AVAudioPCMBuffer(pcmFormat: inFormat, frameCapacity: AVAudioFrameCount(file.length)) else {
                return nil
            }
            try file.read(into: sourceBuffer)

            if inFormat.sampleRate == format.sampleRate,
               inFormat.channelCount == format.channelCount {
                return sourceBuffer
            }

            return convert(sourceBuffer: sourceBuffer, from: inFormat, to: format)
        } catch {
            NSLog("Failed to load sample \(resourcePath): \(error)")
            return nil
        }
    }

    private func resolveResourceURL(path: String) -> URL? {
        guard let baseURL = Bundle.module.resourceURL else { return nil }
        let requested = path as NSString
        let filename = requested.lastPathComponent
        let nsFilename = filename as NSString
        var candidates: [URL] = []

        let directURL = baseURL.appendingPathComponent(path)
        let flatURL = baseURL.appendingPathComponent(filename)
        let bundleURL = Bundle.module.url(
            forResource: nsFilename.deletingPathExtension,
            withExtension: nsFilename.pathExtension
        )
        candidates.append(contentsOf: [directURL, flatURL, bundleURL].compactMap { $0 })

        if requested.pathExtension.lowercased() == "ogg" {
            let wavRelative = requested.deletingPathExtension + ".wav"
            let wavFilename = (wavRelative as NSString).lastPathComponent
            let wavDirect = baseURL.appendingPathComponent(wavRelative)
            let wavFlat = baseURL.appendingPathComponent(wavFilename)
            let wavBundle = Bundle.module.url(
                forResource: (wavFilename as NSString).deletingPathExtension,
                withExtension: "wav"
            )
            candidates.append(contentsOf: [wavDirect, wavFlat, wavBundle].compactMap { $0 })
        }

        return candidates.first {
            FileManager.default.fileExists(atPath: $0.path)
        }
    }

    private func loadPCMBuffer(fileURL: URL) -> AVAudioPCMBuffer? {
        do {
            let file = try AVAudioFile(forReading: fileURL)
            let inFormat = file.processingFormat
            guard let sourceBuffer = AVAudioPCMBuffer(pcmFormat: inFormat, frameCapacity: AVAudioFrameCount(file.length)) else {
                return nil
            }
            try file.read(into: sourceBuffer)
            if inFormat.sampleRate == format.sampleRate,
               inFormat.channelCount == format.channelCount {
                return sourceBuffer
            }
            return convert(sourceBuffer: sourceBuffer, from: inFormat, to: format)
        } catch {
            NSLog("Failed to load custom sample \(fileURL.path): \(error)")
            return nil
        }
    }

    private static func defaultCustomPackDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("Klac/SoundPacks/Custom", isDirectory: true)
    }

    private static func resolveRoot(for directory: URL) -> URL {
        let manifestNames = ["key-down", "press-key", "keydown"]
        guard let items = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return directory }
        let hasSamples = items.contains { item in
            let name = item.deletingPathExtension().lastPathComponent.lowercased()
            return manifestNames.contains { name.hasPrefix($0) }
        }
        if hasSamples { return directory }
        if let nested = items.first(where: { $0.hasDirectoryPath }) {
            return nested
        }
        return directory
    }

    private func convert(sourceBuffer: AVAudioPCMBuffer, from inFormat: AVAudioFormat, to outFormat: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let converter = AVAudioConverter(from: inFormat, to: outFormat) else { return nil }
        let ratio = outFormat.sampleRate / inFormat.sampleRate
        let capacity = AVAudioFrameCount(Double(sourceBuffer.frameLength) * ratio + 64)
        guard let outBuffer = AVAudioPCMBuffer(pcmFormat: outFormat, frameCapacity: capacity) else { return nil }

        var didProvideInput = false
        let status = converter.convert(to: outBuffer, error: nil) { _, outStatus in
            if didProvideInput {
                outStatus.pointee = .noDataNow
                return nil
            }
            didProvideInput = true
            outStatus.pointee = .haveData
            return sourceBuffer
        }
        return status == .haveData || status == .inputRanDry ? outBuffer : nil
    }
}

private extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
