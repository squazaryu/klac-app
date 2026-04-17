import Foundation

final class PlaybackQueueController {
    private let lock = NSLock()
    private var estimatedPlaybackEndTime: CFAbsoluteTime = 0

    func reset() {
        lock.lock()
        estimatedPlaybackEndTime = 0
        lock.unlock()
    }

    func shouldInterrupt(
        now: CFAbsoluteTime,
        bufferSeconds: Double,
        playerIsPlaying: Bool,
        strictLevelingEnabled: Bool
    ) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        if !playerIsPlaying || estimatedPlaybackEndTime < now - 0.45 {
            estimatedPlaybackEndTime = now
        }

        let queuedAhead = max(0, estimatedPlaybackEndTime - now)
        let queueLimit = strictLevelingEnabled ? 0.05 : 0.12
        if queuedAhead > queueLimit {
            estimatedPlaybackEndTime = now + bufferSeconds
            return true
        }

        let start = max(now, estimatedPlaybackEndTime)
        estimatedPlaybackEndTime = start + bufferSeconds
        return false
    }
}
