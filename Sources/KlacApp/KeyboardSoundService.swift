import AppKit
import AVFoundation
import ApplicationServices
import Foundation
import ServiceManagement
import UniformTypeIdentifiers

@MainActor
final class KeyboardSoundService: ObservableObject {
    @Published var isEnabled = true {
        didSet { defaults.set(isEnabled, forKey: Keys.isEnabled) }
    }
    @Published var accessibilityGranted = false
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

    private let soundEngine = ClickSoundEngine()
    private let eventTap = GlobalKeyEventTap()
    @Published var capturingKeyboard = false
    private let defaults = UserDefaults.standard
    private var systemVolumeTimer: Timer?
    private var lastSystemVolume: Double = 1.0

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

        soundEngine.masterVolume = Float(volume)
        soundEngine.variation = Float(variation)
        soundEngine.pressLevel = Float(pressLevel)
        soundEngine.releaseLevel = Float(releaseLevel)
        soundEngine.spaceLevel = Float(spaceLevel)
        soundEngine.setProfile(selectedProfile)
        startSystemVolumeMonitoring()
        updateDynamicCompensation()
        refreshAccessibilityStatus(promptIfNeeded: false)

        eventTap.onEvent = { [weak self] type, keyCode, isAutorepeat in
            guard let self, self.isEnabled else { return }
            if type == .down {
                if isAutorepeat { return }
                self.soundEngine.playDown(for: keyCode, autorepeat: isAutorepeat)
            } else if self.playKeyUp {
                self.soundEngine.playUp(for: keyCode)
            }
        }

        updateLaunchAtLogin()
    }

    func start() {
        refreshAccessibilityStatus(promptIfNeeded: true)
        guard accessibilityGranted else {
            capturingKeyboard = false
            return
        }

        soundEngine.startIfNeeded()
        capturingKeyboard = eventTap.start()
    }

    func stop() {
        eventTap.stop()
        soundEngine.stop()
        capturingKeyboard = false
    }

    func refreshAccessibilityStatus(promptIfNeeded: Bool) {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: promptIfNeeded] as CFDictionary
        accessibilityGranted = AXIsProcessTrustedWithOptions(options)
        if isEnabled, accessibilityGranted {
            soundEngine.startIfNeeded()
            capturingKeyboard = eventTap.start()
        }
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func playTestSound() {
        soundEngine.startIfNeeded()
        soundEngine.playDown(for: 0, autorepeat: false)
        if playKeyUp {
            soundEngine.playUp(for: 0)
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
        systemVolumeTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
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
            await MainActor.run {
                self.lastSystemVolume = normalized
                self.updateDynamicCompensation()
            }
        }
    }

    private func updateDynamicCompensation() {
        guard dynamicCompensationEnabled else {
            soundEngine.dynamicCompensationGain = 1.0
            return
        }
        // More boost when system output is low; soft-limited in audio engine.
        let lowVolumeFactor = max(0.0, 1.0 - lastSystemVolume)
        let gain = 1.0 + lowVolumeFactor * compensationStrength * 1.5
        soundEngine.dynamicCompensationGain = Float(gain).clamped(to: 1.0 ... 3.0)
    }

    nonisolated private static func readSystemOutputVolume() -> Double? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", "output volume of (get volume settings)"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let str = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                  let value = Double(str) else { return nil }
            return value
        } catch {
            return nil
        }
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

    func start() -> Bool {
        if eventTap != nil { return true }

        let mask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)
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

            guard type == .keyDown || type == .keyUp else {
                return Unmanaged.passUnretained(event)
            }

            let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
            let isAutorepeat = event.getIntegerValueField(.keyboardEventAutorepeat) == 1

            DispatchQueue.main.async {
                instance.onEvent?(type == .keyDown ? .down : .up, keyCode, isAutorepeat)
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
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFMachPortSetInvalidationCallBack(tap) { _, _ in }

        eventTap = tap
        runLoopSource = source

        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let tap = eventTap {
            CFMachPortInvalidate(tap)
        }
        runLoopSource = nil
        eventTap = nil
    }
}

enum SoundProfile: String, CaseIterable, Identifiable {
    case g915Tactile
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
        let gain = (masterVolume * keyLevel * dynamicCompensationGain + gainJitter).clamped(to: 0.03 ... 2.5)
        schedule(pool.randomElement(), gain: gain)
    }

    func playUp(for keyCode: Int) {
        guard engine.isRunning else { return }
        if keyCode == 56 || keyCode == 60 || keyCode == 59 || keyCode == 62 {
            return
        }
        let pool: [AVAudioPCMBuffer]
        switch keyCode {
        case 49: pool = bank.spaceUp
        case 36, 76: pool = bank.enterUp
        case 51, 117: pool = bank.backspaceUp
        default: pool = bank.keyUp
        }
        let gain = (masterVolume * releaseLevel * dynamicCompensationGain + Float.random(in: -variation ... variation) * 0.08).clamped(to: 0.02 ... 1.2)
        schedule(pool.randomElement(), gain: gain)
    }

    private func schedule(_ buffer: AVAudioPCMBuffer?, gain: Float) {
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
                dst[i] = Float(tanh(Double(src[i] * gain)))
            }
        }

        player.scheduleBuffer(copy, at: nil, options: .interruptsAtLoop, completionHandler: nil)
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
