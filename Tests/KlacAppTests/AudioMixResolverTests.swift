#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class AudioMixResolverTests: XCTestCase {
    func testResolveVelocityLayerWithThresholds() {
        let layer = AudioMixResolver.resolveVelocityLayer(
            interKeyGap: 0.03,
            stackDensity: 0,
            slamThreshold: 0.045,
            hardThreshold: 0.085,
            mediumThreshold: 0.145
        )
        XCTAssertEqual(layer, .slam)
    }

    func testDownMixInterruptsWhenVeryFastChain() {
        let result = AudioMixResolver.resolveDownMix(
            DownMixInput(
                keyGroup: .alpha,
                autorepeat: false,
                masterVolume: 0.7,
                pressLevel: 1.0,
                spaceLevel: 1.1,
                dynamicCompensationGain: 1.0,
                typingSpeedGain: 1.0,
                variation: 0.3,
                strictLevelingEnabled: false,
                stackModeEnabled: false,
                stackDensity: 0.0,
                minInterKeyGapMs: 30,
                lastDownHitTime: 100.0,
                now: 100.01,
                slamThreshold: 0.045,
                hardThreshold: 0.085,
                mediumThreshold: 0.145,
                jitterRandom: 0.0,
                interruptRandom: 1.0
            )
        )
        XCTAssertTrue(result.interrupt)
    }

    func testUpMixSkipsOnHighDensity() {
        let result = AudioMixResolver.resolveUpMix(
            UpMixInput(
                masterVolume: 0.7,
                releaseLevel: 0.6,
                dynamicCompensationGain: 1.0,
                typingSpeedGain: 1.0,
                variation: 0.3,
                strictLevelingEnabled: false,
                stackModeEnabled: true,
                stackDensity: 0.7,
                releaseDuckingStrength: 0.7,
                releaseDuckingWindowMs: 92,
                releaseTailTightness: 0.4,
                now: 200,
                lastDownHitTime: 199.98,
                jitterRandom: 0,
                releaseKeepRandom: 0,
                releaseInterruptRandom: 0
            )
        )
        if case .skip = result {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected .skip")
        }
    }

    func testSoftKneeCompressCapsValue() {
        let value = AudioMixResolver.softKneeCompress(4.0, kneeStart: 1.6, max: 2.4)
        XCTAssertEqual(value, 2.4, accuracy: 0.0001)
    }
}
#endif
