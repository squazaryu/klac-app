import AVFoundation
import Foundation

final class AudioGraphController {
    private var engine = AVAudioEngine()
    private var player = AVAudioPlayerNode()
    private var engineConfigObserver: NSObjectProtocol?
    private let format: AVAudioFormat

    init(format: AVAudioFormat) {
        self.format = format
        rebuild(onConfigurationChange: {})
    }

    deinit {
        if let engineConfigObserver {
            NotificationCenter.default.removeObserver(engineConfigObserver)
        }
    }

    var isEngineRunning: Bool {
        engine.isRunning
    }

    var isPlayerPlaying: Bool {
        player.isPlaying
    }

    func setMainMixerOutputVolume(_ volume: Float) {
        engine.mainMixerNode.outputVolume = volume
    }

    func startEngine() throws {
        try engine.start()
    }

    func stopEngineAndPlayer() {
        player.stop()
        engine.stop()
    }

    func playPlayer() {
        player.play()
    }

    func scheduleBuffer(_ buffer: AVAudioPCMBuffer, options: AVAudioPlayerNodeBufferOptions) {
        player.scheduleBuffer(buffer, at: nil, options: options, completionHandler: nil)
    }

    func rebuild(onConfigurationChange: @escaping () -> Void) {
        if let engineConfigObserver {
            NotificationCenter.default.removeObserver(engineConfigObserver)
            self.engineConfigObserver = nil
        }

        let newEngine = AVAudioEngine()
        let newPlayer = AVAudioPlayerNode()
        newEngine.attach(newPlayer)
        newEngine.connect(newPlayer, to: newEngine.mainMixerNode, format: format)
        newEngine.mainMixerNode.outputVolume = 1.0
        engine = newEngine
        player = newPlayer

        engineConfigObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: newEngine,
            queue: .main
        ) { _ in
            onConfigurationChange()
        }
    }
}
