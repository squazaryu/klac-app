import AVFoundation
import Foundation

final class PlaybackScheduler {
    private let format: AVAudioFormat
    private let queueController = PlaybackQueueController()
    private(set) var lastPlaybackActivityAt: CFAbsoluteTime = 0

    init(format: AVAudioFormat) {
        self.format = format
    }

    func reset() {
        queueController.reset()
    }

    func hadRecentPlayback(within seconds: CFAbsoluteTime) -> Bool {
        (CFAbsoluteTimeGetCurrent() - lastPlaybackActivityAt) < seconds
    }

    func schedule(
        _ buffer: AVAudioPCMBuffer?,
        gain: Float,
        variation: Float,
        limiterEnabled: Bool,
        limiterDrive: Float,
        strictLevelingEnabled: Bool,
        interruptIfNeeded: Bool,
        graphController: AudioGraphController
    ) {
        guard let buffer else { return }
        guard let copy = PlaybackBufferRenderer.makePlayableCopy(
            from: buffer,
            format: format,
            gain: gain,
            variation: variation,
            limiterEnabled: limiterEnabled,
            limiterDrive: limiterDrive
        ) else { return }

        let now = CFAbsoluteTimeGetCurrent()
        let bufferSeconds = Double(copy.frameLength) / format.sampleRate
        let queueOverflowInterrupt = queueController.shouldInterrupt(
            now: now,
            bufferSeconds: bufferSeconds,
            playerIsPlaying: graphController.isPlayerPlaying,
            strictLevelingEnabled: strictLevelingEnabled
        )

        let shouldInterrupt = interruptIfNeeded || queueOverflowInterrupt
        let options: AVAudioPlayerNodeBufferOptions = shouldInterrupt ? [.interrupts] : []
        graphController.scheduleBuffer(copy, options: options)
        lastPlaybackActivityAt = now
    }
}
