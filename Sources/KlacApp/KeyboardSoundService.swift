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
    @Published var selectedProfile: SoundProfile = .g915Tactile {
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
            updateDynamicCompensation()
        }
    }
    @Published var compensationStrength: Double = 1.0 {
        didSet {
            defaults.set(compensationStrength, forKey: Keys.compensationStrength)
            updateDynamicCompensation()
        }
    }
    @Published var typingAdaptiveEnabled = false {
        didSet {
            defaults.set(typingAdaptiveEnabled, forKey: Keys.typingAdaptiveEnabled)
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
    @Published var abFeature: ABFeature = .core
    @Published var isABPlaying = false
    @Published var currentOutputDeviceName = "Системное устройство"
    @Published var currentOutputDeviceBoost: Double = 1.0 {
        didSet {
            saveCurrentDeviceBoost()
            updateDynamicCompensation()
        }
    }
    @Published var soundPackStatus: String?
    @Published var appearanceMode: AppearanceMode = .system {
        didSet { defaults.set(appearanceMode.rawValue, forKey: Keys.appearanceMode) }
    }

    private let soundEngine = ClickSoundEngine()
    private let eventTap = GlobalKeyEventTap()
    @Published var capturingKeyboard = false
    private let defaults = UserDefaults.standard
    private var systemVolumeTimer: Timer?
    private var lastSystemVolume: Double = 1.0
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
        soundEngine.setProfile(selectedProfile)
        startSystemVolumeMonitoring()
        startTypingDecayMonitoring()
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
        refreshAccessibilityStatus(promptIfNeeded: true)
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
        return "com.tumowuh.klac"
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
            spaceLevel = snapshot.spaceLevel.clamped(to: 0.5 ... 1.8)
        } catch {
            NSLog("Failed to import settings: \(error)")
        }
    }

    func importSoundPack() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.folder, .zip]
        panel.title = "Импорт Sound Pack"
        panel.message = "Выбери папку или zip-архив со звуками."
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let destination = Self.customPackDirectory()
        do {
            try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)

            if url.pathExtension.lowercased() == "zip" {
                try Self.unzipSoundPack(from: url, to: destination)
            } else {
                try Self.copyDirectoryContents(from: url, to: destination)
            }

            if soundEngine.installCustomPack(from: destination) {
                selectedProfile = .customPack
                soundPackStatus = "Sound Pack импортирован."
            } else {
                soundPackStatus = "Не удалось загрузить пак: проверь имена файлов."
            }
        } catch {
            soundPackStatus = "Ошибка импорта: \(error.localizedDescription)"
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

    private func startSystemVolumeMonitoring() {
        systemVolumeTimer?.invalidate()
        systemVolumeTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pollSystemVolume()
            }
        }
        pollSystemVolume()
    }

    private func pollSystemVolume() {
        Task.detached(priority: .background) { [weak self] in
            guard let self else { return }
            let vol = Self.readSystemOutputVolume() ?? 100.0
            let normalized = (vol / 100.0).clamped(to: 0.0 ... 1.0)
            let deviceID = Self.readDefaultOutputDeviceID() ?? 0
            let deviceUID = deviceID != 0 ? (Self.readOutputDeviceUID(deviceID) ?? "") : ""
            let deviceName = deviceID != 0 ? (Self.readOutputDeviceName(deviceID) ?? "Системное устройство") : "Системное устройство"
            await MainActor.run {
                self.lastSystemVolume = normalized
                if deviceID != self.lastOutputDeviceID || deviceUID != self.currentOutputDeviceUID {
                    self.lastOutputDeviceID = deviceID
                    self.currentOutputDeviceUID = deviceUID
                    self.currentOutputDeviceName = deviceName
                    self.currentOutputDeviceBoost = self.outputDeviceBoosts[deviceUID] ?? 1.0
                }
                self.updateDynamicCompensation()
            }
        }
    }

    private func updateDynamicCompensation() {
        guard dynamicCompensationEnabled else {
            soundEngine.dynamicCompensationGain = 1.0
            liveDynamicGain = 1.0
            return
        }
        // Stronger curve so slider movement is audible in normal usage too.
        let lowVolumeFactor = max(0.0, 1.0 - lastSystemVolume)
        let gain = (1.0 + lowVolumeFactor * (0.4 + compensationStrength * 2.6)) * currentOutputDeviceBoost
        let clamped = Float(gain).clamped(to: 1.0 ... 4.0)
        soundEngine.dynamicCompensationGain = clamped
        liveDynamicGain = Double(clamped)
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

    private func recomputeTypingSpeed(now: CFAbsoluteTime) {
        let windowStart = now - 3.0
        typingTimestamps.removeAll { $0 < windowStart }
        let cps = Double(typingTimestamps.count) / 3.0
        typingCPS = cps
        typingWPM = cps * 12.0
        personalBaselineCPS = personalBaselineCPS * 0.985 + cps * 0.015
    }

    private func updateTypingAdaptation() {
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
        liveTypingGain = clamped
    }

    private func saveCurrentDeviceBoost() {
        guard !currentOutputDeviceUID.isEmpty else { return }
        outputDeviceBoosts[currentOutputDeviceUID] = currentOutputDeviceBoost.clamped(to: 0.5 ... 2.0)
        if let data = try? JSONEncoder().encode(outputDeviceBoosts) {
            defaults.set(data, forKey: Keys.outputDeviceBoosts)
        }
    }

    private static func customPackDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("Klac/SoundPacks/Custom", isDirectory: true)
    }

    nonisolated private static func unzipSoundPack(from zipURL: URL, to destination: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-x", "-k", zipURL.path, destination.path]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            throw NSError(domain: "Klac", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "ditto unzip failed"])
        }
    }

    nonisolated private static func copyDirectoryContents(from source: URL, to destination: URL) throws {
        let files = try FileManager.default.contentsOfDirectory(at: source, includingPropertiesForKeys: nil)
        for file in files {
            let target = destination.appendingPathComponent(file.lastPathComponent)
            try FileManager.default.copyItem(at: file, to: target)
        }
    }

    nonisolated private static func readSystemOutputVolume() -> Double? {
        var deviceID = AudioObjectID(0)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        var defaultDeviceAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let defaultDeviceStatus = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &defaultDeviceAddress,
            0,
            nil,
            &size,
            &deviceID
        )
        guard defaultDeviceStatus == noErr, deviceID != 0 else { return nil }

        // Try virtual master first.
        var volume = Float32(0)
        size = UInt32(MemoryLayout<Float32>.size)
        var volumeAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        let masterStatus = AudioObjectGetPropertyData(
            deviceID,
            &volumeAddress,
            0,
            nil,
            &size,
            &volume
        )
        if masterStatus == noErr {
            return Double(volume * 100)
        }

        // Fallback to left/right average for devices without master control.
        let channels: [UInt32] = [1, 2]
        var values: [Double] = []
        for channel in channels {
            volumeAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyVolumeScalar,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: channel
            )
            var channelVolume = Float32(0)
            size = UInt32(MemoryLayout<Float32>.size)
            let channelStatus = AudioObjectGetPropertyData(
                deviceID,
                &volumeAddress,
                0,
                nil,
                &size,
                &channelVolume
            )
            if channelStatus == noErr {
                values.append(Double(channelVolume))
            }
        }
        guard !values.isEmpty else { return nil }
        let avg = values.reduce(0, +) / Double(values.count)
        return avg * 100
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
    case g915Tactile
    case customPack
    case holyPanda
    case gateronBlackInk
    case mxBrown
    case mxBlack
    case gateronRedInk
    case alpaca

    var id: String { rawValue }

    var title: String {
        switch self {
        case .g915Tactile: return "G915 Tactile"
        case .customPack: return "Custom Pack"
        case .holyPanda: return "Holy Panda"
        case .gateronBlackInk: return "Gateron Black Ink"
        case .mxBrown: return "MX Brown"
        case .mxBlack: return "MX Black"
        case .gateronRedInk: return "Gateron Red Ink"
        case .alpaca: return "Alpaca"
        }
    }
}

final class ClickSoundEngine {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 2)!

    var masterVolume: Float = 0.75
    var variation: Float = 0.3
    var pressLevel: Float = 1.0
    var releaseLevel: Float = 0.65
    var spaceLevel: Float = 1.1
    var dynamicCompensationGain: Float = 1.0
    var typingSpeedGain: Float = 1.0
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

    init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = masterVolume
    }

    func setProfile(_ profile: SoundProfile) {
        switch profile {
        case .g915Tactile:
            bank = loadBank(
                keyDown: [
                    "Sounds/g915/g915-key-press-1.wav",
                    "Sounds/g915/g915-key-press-2.wav",
                    "Sounds/g915/g915-key-press-3.wav",
                    "Sounds/g915/g915-key-press-4.wav",
                    "Sounds/g915/g915-key-press-5.wav"
                ],
                keyUp: [
                    "Sounds/g915/g915-key-release-1.wav",
                    "Sounds/g915/g915-key-release-2.wav",
                    "Sounds/g915/g915-key-release-3.wav",
                    "Sounds/g915/g915-key-release-4.wav",
                    "Sounds/g915/g915-key-release-5.wav"
                ],
                spaceDown: [
                    "Sounds/g915/g915-space-press-1.wav",
                    "Sounds/g915/g915-space-press-2.wav",
                    "Sounds/g915/g915-space-press-3.wav"
                ],
                spaceUp: [
                    "Sounds/g915/g915-space-release-1.wav",
                    "Sounds/g915/g915-space-release-2.wav",
                    "Sounds/g915/g915-space-release-3.wav"
                ],
                enterDown: [
                    "Sounds/g915/g915-enter-press-1.wav",
                    "Sounds/g915/g915-enter-press-2.wav"
                ],
                enterUp: [
                    "Sounds/g915/g915-enter-release-1.wav",
                    "Sounds/g915/g915-enter-release-2.wav"
                ],
                backspaceDown: [
                    "Sounds/g915/g915-key-press-2.wav",
                    "Sounds/g915/g915-key-press-4.wav"
                ],
                backspaceUp: [
                    "Sounds/g915/g915-key-release-2.wav",
                    "Sounds/g915/g915-key-release-4.wav"
                ]
            )
        case .customPack:
            if let root = customPackRoot, installCustomPack(from: root) {
                return
            }
            let fallback = Self.defaultCustomPackDirectory()
            if installCustomPack(from: fallback) {
                return
            }
            bank = loadBank(
                keyDown: ["Sounds/g915/g915-key-press-1.wav"],
                keyUp: ["Sounds/g915/g915-key-release-1.wav"],
                spaceDown: ["Sounds/g915/g915-space-press-1.wav"],
                spaceUp: ["Sounds/g915/g915-space-release-1.wav"],
                enterDown: ["Sounds/g915/g915-enter-press-1.wav"],
                enterUp: ["Sounds/g915/g915-enter-release-1.wav"],
                backspaceDown: ["Sounds/g915/g915-key-press-2.wav"],
                backspaceUp: ["Sounds/g915/g915-key-release-2.wav"]
            )
        case .holyPanda:
            bank = loadBank(
                keyDown: [
                    "Sounds/holypanda/holypanda-press_key1.mp3",
                    "Sounds/holypanda/holypanda-press_key2.mp3",
                    "Sounds/holypanda/holypanda-press_key3.mp3",
                    "Sounds/holypanda/holypanda-press_key4.mp3",
                    "Sounds/holypanda/holypanda-press_key5.mp3"
                ],
                keyUp: [
                    "Sounds/holypanda/holypanda-release_key.mp3"
                ],
                spaceDown: ["Sounds/holypanda/holypanda-press_space.mp3"],
                spaceUp: ["Sounds/holypanda/holypanda-release_space.mp3"],
                enterDown: ["Sounds/holypanda/holypanda-press_enter.mp3"],
                enterUp: ["Sounds/holypanda/holypanda-release_enter.mp3"],
                backspaceDown: ["Sounds/holypanda/holypanda-press_back.mp3"],
                backspaceUp: ["Sounds/holypanda/holypanda-release_back.mp3"]
            )
        case .gateronBlackInk:
            bank = loadBank(
                keyDown: [
                    "Sounds/gateronblack/gateronblack-press_key1.mp3",
                    "Sounds/gateronblack/gateronblack-press_key2.mp3",
                    "Sounds/gateronblack/gateronblack-press_key3.mp3",
                    "Sounds/gateronblack/gateronblack-press_key4.mp3",
                    "Sounds/gateronblack/gateronblack-press_key5.mp3"
                ],
                keyUp: [
                    "Sounds/gateronblack/gateronblack-release_key.mp3"
                ],
                spaceDown: ["Sounds/gateronblack/gateronblack-press_space.mp3"],
                spaceUp: ["Sounds/gateronblack/gateronblack-release_space.mp3"],
                enterDown: ["Sounds/gateronblack/gateronblack-press_enter.mp3"],
                enterUp: ["Sounds/gateronblack/gateronblack-release_enter.mp3"],
                backspaceDown: ["Sounds/gateronblack/gateronblack-press_back.mp3"],
                backspaceUp: ["Sounds/gateronblack/gateronblack-release_back.mp3"]
            )
        case .mxBrown:
            bank = loadBank(
                keyDown: [
                    "Sounds/mxbrown/mxbrown-press_key1.mp3",
                    "Sounds/mxbrown/mxbrown-press_key2.mp3",
                    "Sounds/mxbrown/mxbrown-press_key3.mp3",
                    "Sounds/mxbrown/mxbrown-press_key4.mp3",
                    "Sounds/mxbrown/mxbrown-press_key5.mp3"
                ],
                keyUp: ["Sounds/mxbrown/mxbrown-release_key.mp3"],
                spaceDown: ["Sounds/mxbrown/mxbrown-press_space.mp3"],
                spaceUp: ["Sounds/mxbrown/mxbrown-release_space.mp3"],
                enterDown: ["Sounds/mxbrown/mxbrown-press_enter.mp3"],
                enterUp: ["Sounds/mxbrown/mxbrown-release_enter.mp3"],
                backspaceDown: ["Sounds/mxbrown/mxbrown-press_back.mp3"],
                backspaceUp: ["Sounds/mxbrown/mxbrown-release_back.mp3"]
            )
        case .mxBlack:
            bank = loadBank(
                keyDown: [
                    "Sounds/mxblack/mxblack-press_key1.mp3",
                    "Sounds/mxblack/mxblack-press_key2.mp3",
                    "Sounds/mxblack/mxblack-press_key3.mp3",
                    "Sounds/mxblack/mxblack-press_key4.mp3",
                    "Sounds/mxblack/mxblack-press_key5.mp3"
                ],
                keyUp: ["Sounds/mxblack/mxblack-release_key.mp3"],
                spaceDown: ["Sounds/mxblack/mxblack-press_space.mp3"],
                spaceUp: ["Sounds/mxblack/mxblack-release_space.mp3"],
                enterDown: ["Sounds/mxblack/mxblack-press_enter.mp3"],
                enterUp: ["Sounds/mxblack/mxblack-release_enter.mp3"],
                backspaceDown: ["Sounds/mxblack/mxblack-press_back.mp3"],
                backspaceUp: ["Sounds/mxblack/mxblack-release_back.mp3"]
            )
        case .gateronRedInk:
            bank = loadBank(
                keyDown: [
                    "Sounds/gateronred/gateronred-press_key1.mp3",
                    "Sounds/gateronred/gateronred-press_key2.mp3",
                    "Sounds/gateronred/gateronred-press_key3.mp3",
                    "Sounds/gateronred/gateronred-press_key4.mp3",
                    "Sounds/gateronred/gateronred-press_key5.mp3"
                ],
                keyUp: ["Sounds/gateronred/gateronred-release_key.mp3"],
                spaceDown: ["Sounds/gateronred/gateronred-press_space.mp3"],
                spaceUp: ["Sounds/gateronred/gateronred-release_space.mp3"],
                enterDown: ["Sounds/gateronred/gateronred-press_enter.mp3"],
                enterUp: ["Sounds/gateronred/gateronred-release_enter.mp3"],
                backspaceDown: ["Sounds/gateronred/gateronred-press_back.mp3"],
                backspaceUp: ["Sounds/gateronred/gateronred-release_back.mp3"]
            )
        case .alpaca:
            bank = loadBank(
                keyDown: [
                    "Sounds/alpaca/alpaca-press_key1.mp3",
                    "Sounds/alpaca/alpaca-press_key2.mp3",
                    "Sounds/alpaca/alpaca-press_key3.mp3",
                    "Sounds/alpaca/alpaca-press_key4.mp3",
                    "Sounds/alpaca/alpaca-press_key5.mp3"
                ],
                keyUp: ["Sounds/alpaca/alpaca-release_key.mp3"],
                spaceDown: ["Sounds/alpaca/alpaca-press_space.mp3"],
                spaceUp: ["Sounds/alpaca/alpaca-release_space.mp3"],
                enterDown: ["Sounds/alpaca/alpaca-press_enter.mp3"],
                enterUp: ["Sounds/alpaca/alpaca-release_enter.mp3"],
                backspaceDown: ["Sounds/alpaca/alpaca-press_back.mp3"],
                backspaceUp: ["Sounds/alpaca/alpaca-release_back.mp3"]
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
                engine.mainMixerNode.outputVolume = masterVolume
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
    }

    func playDown(for keyCode: Int, autorepeat: Bool) {
        guard engine.isRunning else { return }

        let pool: [AVAudioPCMBuffer]
        let keyLevel: Float
        switch keyCode {
        case 49:
            pool = bank.spaceDown
            keyLevel = spaceLevel
        case 36, 76:
            pool = bank.enterDown
            keyLevel = (pressLevel + spaceLevel) * 0.5
        case 51, 117:
            pool = bank.backspaceDown
            keyLevel = pressLevel * 0.95
        default:
            pool = bank.keyDown
            keyLevel = pressLevel
        }

        var gainJitter = Float.random(in: -variation ... variation) * 0.18
        if autorepeat { gainJitter -= 0.1 }
        var gain = (masterVolume * keyLevel * dynamicCompensationGain * typingSpeedGain + gainJitter).clamped(to: 0.03 ... 2.8)
        var interrupt = false
        if stackModeEnabled {
            let now = CFAbsoluteTimeGetCurrent()
            let dt = now - lastDownHitTime
            lastDownHitTime = now
            let density = stackDensity.clamped(to: 0.0 ... 1.0)
            let proximity = Float(max(0.0, 1.0 - dt / 0.18))
            let stackBoost = 1.0 + (density * density) * proximity * 3.2
            gain = (gain * stackBoost).clamped(to: 0.03 ... 3.4)
            interrupt = density > 0.25
        }
        schedule(pool.randomElement(), gain: gain, interruptIfNeeded: interrupt)
    }

    func playUp(for keyCode: Int) {
        guard engine.isRunning else { return }
        if stackModeEnabled {
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
        switch keyCode {
        case 49: pool = bank.spaceUp
        case 36, 76: pool = bank.enterUp
        case 51, 117: pool = bank.backspaceUp
        default: pool = bank.keyUp
        }
        var gain = (masterVolume * releaseLevel * dynamicCompensationGain * typingSpeedGain + Float.random(in: -variation ... variation) * 0.08).clamped(to: 0.02 ... 1.3)
        if stackModeEnabled {
            let tailCut = (1.0 - stackDensity * 0.9).clamped(to: 0.08 ... 1.0)
            gain = (gain * tailCut).clamped(to: 0.01 ... 1.3)
        }
        let interrupt = stackModeEnabled && stackDensity > 0.25
        schedule(pool.randomElement(), gain: gain, interruptIfNeeded: interrupt)
    }

    private func schedule(_ buffer: AVAudioPCMBuffer?, gain: Float, interruptIfNeeded: Bool) {
        guard let buffer else { return }
        engine.mainMixerNode.outputVolume = masterVolume
        // Duplicate buffer with per-hit gain for low-latency playback without re-synthesis.
        guard let copy = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: buffer.frameCapacity) else { return }
        copy.frameLength = buffer.frameLength

        let channels = Int(format.channelCount)
        let frames = Int(buffer.frameLength)
        for channel in 0 ..< channels {
            guard let src = buffer.floatChannelData?[channel],
                  let dst = copy.floatChannelData?[channel] else { continue }
            for i in 0 ..< frames {
                let pre = src[i] * gain
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

        // Only allow interruption for release tails; keep key-down attacks stable.
        let options: AVAudioPlayerNodeBufferOptions = interruptIfNeeded ? [.interrupts] : []
        player.scheduleBuffer(copy, at: nil, options: options, completionHandler: nil)
        if !player.isPlaying {
            player.play()
        }
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
        guard let baseURL = Bundle.module.resourceURL else {
            NSLog("Bundle.module.resourceURL is missing")
            return nil
        }

        let directURL = baseURL.appendingPathComponent(resourcePath)
        let filename = (resourcePath as NSString).lastPathComponent
        let flatURL = baseURL.appendingPathComponent(filename)
        let nsFilename = filename as NSString
        let bundleURL = Bundle.module.url(
            forResource: nsFilename.deletingPathExtension,
            withExtension: nsFilename.pathExtension
        )

        let candidateURL = [directURL, flatURL, bundleURL].compactMap { $0 }.first {
            FileManager.default.fileExists(atPath: $0.path)
        }

        guard let url = candidateURL else {
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
