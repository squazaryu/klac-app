import AVFoundation
import Foundation

final class ClickSoundEngine {
    private let audioQueue = DispatchQueue(label: "Klac.AudioEngineQueue", qos: .userInteractive)
    private let audioQueueKey = DispatchSpecificKey<UInt8>()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 2)!
    private lazy var graphController = AudioGraphController(format: format)

    var masterVolume: Float = 0.75
    var variation: Float = 0.3
    var pitchVariationAmount: Float = 0.22
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
    var minInterKeyGapMs: Float = 14
    var releaseDuckingStrength: Float = 0.72
    var releaseDuckingWindowMs: Float = 92
    var releaseTailTightness: Float = 0.38
    var onVelocityLayerChanged: ((String) -> Void)?
    var onManifestValidation: ((String, [String]) -> Void)?
    var onDiagnostic: ((String) -> Void)?
    private var lastDownHitTime: CFAbsoluteTime = 0
    private var slamThreshold: CFAbsoluteTime = 0.045
    private var hardThreshold: CFAbsoluteTime = 0.085
    private var mediumThreshold: CFAbsoluteTime = 0.145
    private var lastReportedLayer: VelocityLayer?

    private var bank = SampleBank.empty
    private var customPackRoot: URL?
    private enum SampleGroup: Hashable {
        case keyDown(KeyGroup, VelocityLayer)
        case keyUp(KeyGroup)
    }
    private let samplePicker = SamplePicker<SampleGroup>()
    private var lastOutputDeviceReinit: CFAbsoluteTime = 0
    private var graphReadyAfter: CFAbsoluteTime = 0
    private lazy var playbackScheduler = PlaybackScheduler(format: format)
    private var currentProfile: SoundProfile = .kalihBoxWhite
    private var keepEngineRunning = true

    init() {
        audioQueue.setSpecific(key: audioQueueKey, value: 1)
        onAudioQueueSync {
            rebuildAudioGraph()
        }
    }

    func setProfile(_ profile: SoundProfile) {
        onAudioQueueSync {
            currentProfile = profile
            bank = loadProfileBank(for: profile)
        }
    }

    func reloadCurrentProfile() {
        onAudioQueueSync {
            setProfile(currentProfile)
        }
    }

    func installCustomPack(from root: URL) -> Bool {
        onAudioQueueSync {
            let resolvedRoot = Self.resolveRoot(for: root)
            let loaded = loadBankFromDirectory(resolvedRoot)
            guard !loaded.downSamples(for: .alpha, layer: .medium).isEmpty,
                  !loaded.downLayers.isEmpty else { return false }
            customPackRoot = resolvedRoot
            bank = loaded
            return true
        }
    }

    private func loadProfileBank(for profile: SoundProfile) -> SampleBank {
        let source = SoundProfileSource.resolve(for: profile)
        switch source.kind {
        case .customPack:
            return loadCustomPackOrFallback()
        case let .manifestOnly(resourceDirectory, configFilename):
            return loadBankFromManifest(
                resourceDirectory: resourceDirectory,
                configFilename: configFilename
            )
        case let .manifestOrMechvibes(resourceDirectory, manifestFilename, mechvibesConfigFilename):
            let manifest = loadBankFromManifest(
                resourceDirectory: resourceDirectory,
                configFilename: manifestFilename
            )
            if !manifest.downLayers.isEmpty {
                return manifest
            }
            return loadBankFromMechvibesConfig(
                resourceDirectory: resourceDirectory,
                configFilename: mechvibesConfigFilename
            )
        case let .mechvibesConfig(resourceDirectory, configFilename):
            return loadBankFromMechvibesConfig(
                resourceDirectory: resourceDirectory,
                configFilename: configFilename
            )
        }
    }

    private func loadCustomPackOrFallback() -> SampleBank {
        if let root = customPackRoot, installCustomPack(from: root) {
            return bank
        }
        let fallback = Self.defaultCustomPackDirectory()
        if installCustomPack(from: fallback) {
            return bank
        }
        return loadBank(
            keyDown: ["Sounds/kalihboxwhite/kalihboxwhite-press_key1.mp3"],
            keyUp: ["Sounds/kalihboxwhite/kalihboxwhite-release_key.mp3"],
            spaceDown: ["Sounds/kalihboxwhite/kalihboxwhite-press_space.mp3"],
            spaceUp: ["Sounds/kalihboxwhite/kalihboxwhite-release_space.mp3"],
            enterDown: ["Sounds/kalihboxwhite/kalihboxwhite-press_enter.mp3"],
            enterUp: ["Sounds/kalihboxwhite/kalihboxwhite-release_enter.mp3"],
            backspaceDown: ["Sounds/kalihboxwhite/kalihboxwhite-press_back.mp3"],
            backspaceUp: ["Sounds/kalihboxwhite/kalihboxwhite-release_back.mp3"]
        )
    }

    func startIfNeeded() {
        onAudioQueueSync {
            keepEngineRunning = true
            if !graphController.isEngineRunning {
                do {
                    graphController.setMainMixerOutputVolume(1.0)
                    try graphController.startEngine()
                    diagnostic("engine started")
                } catch {
                    diagnostic("engine start failed: \(error.localizedDescription)")
                    return
                }
            }

            if !graphController.isPlayerPlaying {
                graphController.playPlayer()
            }
        }
    }

    func stop() {
        onAudioQueueSync {
            keepEngineRunning = false
            graphController.stopEngineAndPlayer()
            playbackScheduler.reset()
        }
    }

    func handleOutputDeviceChanged() {
        onAudioQueueSync {
            let wasRunning = graphController.isEngineRunning
            let shouldBeRunning = keepEngineRunning || wasRunning
            let now = CFAbsoluteTimeGetCurrent()
            // Debounce noisy route notifications.
            if now - lastOutputDeviceReinit < 0.45 { return }
            lastOutputDeviceReinit = now

            rebuildAudioGraph()
            if shouldBeRunning {
                startIfNeeded()
            }
            graphReadyAfter = CFAbsoluteTimeGetCurrent() + 0.06
            diagnostic("engine graph rebuilt after output-device change")
        }
    }

    func setVelocityThresholds(slam: Double, hard: Double, medium: Double) {
        onAudioQueueSync {
            let s = slam.clamped(to: 0.010 ... 0.120)
            let h = max(s + 0.006, hard).clamped(to: 0.025 ... 0.180)
            let m = max(h + 0.006, medium).clamped(to: 0.040 ... 0.260)
            slamThreshold = s
            hardThreshold = h
            mediumThreshold = m
        }
    }

    private func rebuildAudioGraph() {
        graphController.rebuild { [weak self] in
            self?.handleOutputDeviceChanged()
        }

        playbackScheduler.reset()
    }

    func playDown(for keyCode: Int, autorepeat: Bool) {
        onAudioQueueAsync { [weak self] in
            self?._playDown(for: keyCode, autorepeat: autorepeat)
        }
    }

    func playUp(for keyCode: Int) {
        onAudioQueueAsync { [weak self] in
            self?._playUp(for: keyCode)
        }
    }

    func runFailSafeTick() {
        onAudioQueueAsync { [weak self] in
            guard let self else { return }
            if keepEngineRunning && !graphController.isEngineRunning {
                startIfNeeded()
                diagnostic("fail-safe: audio engine restarted")
            } else if keepEngineRunning, !graphController.isPlayerPlaying, playbackScheduler.hadRecentPlayback(within: 1.8) {
                graphController.playPlayer()
                diagnostic("fail-safe: player resumed")
            }
        }
    }

    private func _playDown(for keyCode: Int, autorepeat: Bool) {
        if CFAbsoluteTimeGetCurrent() < graphReadyAfter {
            return
        }
        if keepEngineRunning {
            startIfNeeded()
        }
        guard graphController.isEngineRunning else { return }

        let keyGroup = resolveKeyGroup(for: keyCode)
        let now = CFAbsoluteTimeGetCurrent()
        let effectiveVariation = max(0.10, variation)
        let downMix = AudioMixResolver.resolveDownMix(
            DownMixInput(
                keyGroup: keyGroup,
                autorepeat: autorepeat,
                masterVolume: masterVolume,
                pressLevel: pressLevel,
                spaceLevel: spaceLevel,
                dynamicCompensationGain: dynamicCompensationGain,
                typingSpeedGain: typingSpeedGain,
                variation: variation,
                strictLevelingEnabled: strictLevelingEnabled,
                stackModeEnabled: stackModeEnabled,
                stackDensity: stackDensity,
                minInterKeyGapMs: minInterKeyGapMs,
                lastDownHitTime: lastDownHitTime,
                now: now,
                slamThreshold: slamThreshold,
                hardThreshold: hardThreshold,
                mediumThreshold: mediumThreshold,
                jitterRandom: Float.random(in: -effectiveVariation ... effectiveVariation),
                interruptRandom: Float.random(in: 0 ... 1)
            )
        )
        lastDownHitTime = downMix.nextLastDownHitTime
        let layer = downMix.layer
        if lastReportedLayer != layer {
            lastReportedLayer = layer
            onVelocityLayerChanged?(layer.rawValue)
        }
        let pool = bank.downSamples(for: keyGroup, layer: layer)
        let sampleGroup = SampleGroup.keyDown(keyGroup, layer)
        schedule(
            samplePicker.pick(from: pool, group: sampleGroup),
            gain: downMix.gain,
            interruptIfNeeded: downMix.interrupt
        )
    }

    private func _playUp(for keyCode: Int) {
        if CFAbsoluteTimeGetCurrent() < graphReadyAfter {
            return
        }
        if keepEngineRunning {
            startIfNeeded()
        }
        guard graphController.isEngineRunning else { return }
        let keyGroup = resolveKeyGroup(for: keyCode)
        let pool = bank.releasePool(for: keyGroup)
        let group = SampleGroup.keyUp(keyGroup)
        let effectiveVariation = max(0.10, variation)
        let now = CFAbsoluteTimeGetCurrent()
        let upMix = AudioMixResolver.resolveUpMix(
            UpMixInput(
                masterVolume: masterVolume,
                releaseLevel: releaseLevel,
                dynamicCompensationGain: dynamicCompensationGain,
                typingSpeedGain: typingSpeedGain,
                variation: variation,
                strictLevelingEnabled: strictLevelingEnabled,
                stackModeEnabled: stackModeEnabled,
                stackDensity: stackDensity,
                releaseDuckingStrength: releaseDuckingStrength,
                releaseDuckingWindowMs: releaseDuckingWindowMs,
                releaseTailTightness: releaseTailTightness,
                now: now,
                lastDownHitTime: lastDownHitTime,
                jitterRandom: Float.random(in: -effectiveVariation ... effectiveVariation),
                releaseKeepRandom: Float.random(in: 0 ... 1),
                releaseInterruptRandom: Float.random(in: 0 ... 1)
            )
        )
        switch upMix {
        case .skip:
            return
        case .play(let gain, let interrupt):
            schedule(samplePicker.pick(from: pool, group: group), gain: gain, interruptIfNeeded: interrupt)
        }
    }

    private func resolveKeyGroup(for keyCode: Int) -> KeyGroup {
        switch keyCode {
        case 49:
            return .space
        case 36, 76:
            return .enter
        case 51, 117:
            return .delete
        case 53, 122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111, 105, 107, 113, 106, 64, 79, 80, 90:
            return .function
        case 123, 124, 125, 126:
            return .arrow
        case 54, 55, 56, 57, 58, 59, 60, 61, 62:
            return .modifier
        default:
            return .alpha
        }
    }

    private func schedule(_ buffer: AVAudioPCMBuffer?, gain: Float, interruptIfNeeded: Bool) {
        playbackScheduler.schedule(
            buffer,
            gain: gain,
            variation: variation,
            limiterEnabled: limiterEnabled,
            limiterDrive: limiterDrive,
            strictLevelingEnabled: strictLevelingEnabled,
            interruptIfNeeded: interruptIfNeeded,
            graphController: graphController
        )
    }

    private func onAudioQueueAsync(_ work: @escaping () -> Void) {
        audioQueue.async(execute: work)
    }

    private func onAudioQueueSync<T>(_ work: () -> T) -> T {
        if DispatchQueue.getSpecific(key: audioQueueKey) != nil {
            return work()
        }
        return audioQueue.sync(execute: work)
    }

    private func diagnostic(_ message: String) {
        samplePackLoader.diagnostic(message)
    }

    private var samplePackLoader: SamplePackLoader {
        SamplePackLoader(
            format: format,
            pitchVariationAmount: pitchVariationAmount,
            onManifestValidation: onManifestValidation,
            diagnostic: onDiagnostic
        )
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
        samplePackLoader.loadBank(
            keyDown: keyDown,
            keyUp: keyUp,
            spaceDown: spaceDown,
            spaceUp: spaceUp,
            enterDown: enterDown,
            enterUp: enterUp,
            backspaceDown: backspaceDown,
            backspaceUp: backspaceUp,
            fallback: bank
        )
    }

    private func loadBankFromDirectory(_ root: URL) -> SampleBank {
        samplePackLoader.loadBankFromDirectory(root, fallback: bank)
    }

    private func loadBankFromMechvibesConfig(resourceDirectory: String, configFilename: String) -> SampleBank {
        samplePackLoader.loadBankFromMechvibesConfig(
            resourceDirectory: resourceDirectory,
            configFilename: configFilename,
            fallback: bank
        )
    }

    private func loadBankFromManifest(resourceDirectory: String, configFilename: String = "pack.json") -> SampleBank {
        samplePackLoader.loadBankFromManifest(
            resourceDirectory: resourceDirectory,
            configFilename: configFilename,
            fallback: bank
        )
    }

    private static func defaultCustomPackDirectory() -> URL {
        SamplePackLoader.defaultCustomPackDirectory()
    }

    private static func resolveRoot(for directory: URL) -> URL {
        SamplePackLoader.resolveRoot(for: directory)
    }
}
