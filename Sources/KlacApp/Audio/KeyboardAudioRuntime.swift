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
    private var rebuildState = OutputDeviceRebuildState()
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
        return ProfileBankLoadCoordinator.load(
            sourceKind: source.kind,
            loadCustomPackOrFallback: { [weak self] in
                self?.loadCustomPackOrFallback() ?? .empty
            },
            loadManifest: { [weak self] resourceDirectory, configFilename in
                self?.loadBankFromManifest(
                    resourceDirectory: resourceDirectory,
                    configFilename: configFilename
                ) ?? .empty
            },
            loadMechvibesConfig: { [weak self] resourceDirectory, configFilename in
                self?.loadBankFromMechvibesConfig(
                    resourceDirectory: resourceDirectory,
                    configFilename: configFilename
                ) ?? .empty
            }
        )
    }

    private func loadCustomPackOrFallback() -> SampleBank {
        CustomPackFallbackCoordinator.load(
            customPackRoot: customPackRoot,
            defaultCustomPackDirectory: { Self.defaultCustomPackDirectory() },
            installCustomPack: { [weak self] root in
                self?.installCustomPack(from: root) ?? false
            },
            currentBank: { [weak self] in
                self?.bank ?? .empty
            },
            fallbackBank: { [weak self] in
                let paths = BundledFallbackPackProvider.kalihBoxWhite()
                return self?.loadBank(
                    keyDown: paths.keyDown,
                    keyUp: paths.keyUp,
                    spaceDown: paths.spaceDown,
                    spaceUp: paths.spaceUp,
                    enterDown: paths.enterDown,
                    enterUp: paths.enterUp,
                    backspaceDown: paths.backspaceDown,
                    backspaceUp: paths.backspaceUp
                ) ?? .empty
            }
        )
    }

    func startIfNeeded() {
        onAudioQueueSync {
            keepEngineRunning = true
            let plan = AudioStartCoordinator.makePlan(
                engineRunning: graphController.isEngineRunning,
                playerPlaying: graphController.isPlayerPlaying
            )
            if plan.shouldStartEngine {
                do {
                    graphController.setMainMixerOutputVolume(1.0)
                    try graphController.startEngine()
                    diagnostic("engine started")
                } catch {
                    diagnostic("engine start failed: \(error.localizedDescription)")
                    return
                }
            }

            if plan.shouldPlayPlayer {
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
            let now = CFAbsoluteTimeGetCurrent()
            let plan = AudioRouteChangeCoordinator.makePlan(
                keepEngineRunning: keepEngineRunning,
                engineRunning: graphController.isEngineRunning,
                now: now,
                rebuildState: rebuildState
            )
            guard plan.shouldRebuildGraph else { return }

            rebuildAudioGraph()
            if plan.shouldStartAfterRebuild {
                startIfNeeded()
            }
            AudioRouteChangeCoordinator.markRebuilt(state: &rebuildState, at: now)
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
            let action = AudioEngineFailSafeCoordinator.decide(
                keepEngineRunning: keepEngineRunning,
                engineRunning: graphController.isEngineRunning,
                playerPlaying: graphController.isPlayerPlaying,
                hadRecentPlayback: playbackScheduler.hadRecentPlayback(within: 1.8)
            )
            switch action {
            case .restartEngine:
                startIfNeeded()
                diagnostic("fail-safe: audio engine restarted")
            case .resumePlayer:
                graphController.playPlayer()
                diagnostic("fail-safe: player resumed")
            case .none:
                break
            }
        }
    }

    private func _playDown(for keyCode: Int, autorepeat: Bool) {
        let now = CFAbsoluteTimeGetCurrent()
        let preflight = PlaybackPreflightCoordinator.makePlan(
            canPlay: OutputDeviceRebuildCoordinator.canPlay(now: now, state: rebuildState),
            keepEngineRunning: keepEngineRunning
        )
        guard preflight.shouldContinue else { return }
        if preflight.shouldStartEngine {
            startIfNeeded()
        }
        guard graphController.isEngineRunning else { return }

        let keyGroup = KeyCodeClassifier.resolveKeyGroup(for: keyCode)
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
        let layerChange = VelocityLayerChangeCoordinator.makePlan(
            lastReportedLayer: lastReportedLayer,
            nextLayer: layer
        )
        lastReportedLayer = layerChange.nextLastReportedLayer
        if layerChange.shouldNotify {
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
        let now = CFAbsoluteTimeGetCurrent()
        let preflight = PlaybackPreflightCoordinator.makePlan(
            canPlay: OutputDeviceRebuildCoordinator.canPlay(now: now, state: rebuildState),
            keepEngineRunning: keepEngineRunning
        )
        guard preflight.shouldContinue else { return }
        if preflight.shouldStartEngine {
            startIfNeeded()
        }
        guard graphController.isEngineRunning else { return }
        let keyGroup = KeyCodeClassifier.resolveKeyGroup(for: keyCode)
        let pool = bank.releasePool(for: keyGroup)
        let group = SampleGroup.keyUp(keyGroup)
        let effectiveVariation = max(0.10, variation)
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
