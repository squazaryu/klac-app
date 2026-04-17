#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class PlaybackQueueControllerTests: XCTestCase {
    func testShouldInterruptWhenQueueAheadExceedsLimit() {
        let queue = PlaybackQueueController()
        let now: CFAbsoluteTime = 10.0

        XCTAssertFalse(queue.shouldInterrupt(
            now: now,
            bufferSeconds: 0.06,
            playerIsPlaying: true,
            strictLevelingEnabled: false
        ))
        XCTAssertFalse(queue.shouldInterrupt(
            now: now + 0.001,
            bufferSeconds: 0.06,
            playerIsPlaying: true,
            strictLevelingEnabled: false
        ))
        XCTAssertTrue(queue.shouldInterrupt(
            now: now + 0.002,
            bufferSeconds: 0.06,
            playerIsPlaying: true,
            strictLevelingEnabled: false
        ))
    }

    func testResetClearsEstimatedQueue() {
        let queue = PlaybackQueueController()
        let now: CFAbsoluteTime = 20.0

        _ = queue.shouldInterrupt(
            now: now,
            bufferSeconds: 0.08,
            playerIsPlaying: true,
            strictLevelingEnabled: false
        )
        queue.reset()
        XCTAssertFalse(queue.shouldInterrupt(
            now: now + 0.01,
            bufferSeconds: 0.08,
            playerIsPlaying: true,
            strictLevelingEnabled: false
        ))
    }
}
#endif
