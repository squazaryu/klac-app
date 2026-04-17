#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class AudioCompensationMathTests: XCTestCase {
    func testAutoInverseGainClampsAtLowSystemVolume() {
        let gain = AudioCompensationMath.autoInverseGain(systemVolumeScalar: 0.0, targetAt100: 0.45)
        XCTAssertGreaterThanOrEqual(gain, 0.20)
        XCTAssertLessThanOrEqual(gain, 12.0)
    }

    func testAutoInverseGainDecreasesWhenSystemVolumeIncreases() {
        let low = AudioCompensationMath.autoInverseGain(systemVolumeScalar: 0.30, targetAt100: 0.45)
        let high = AudioCompensationMath.autoInverseGain(systemVolumeScalar: 1.0, targetAt100: 0.45)
        XCTAssertGreaterThan(low, high)
    }

    func testCurveGainInterpolatesLinearly() {
        let points = [
            GainCurvePoint(x: 0.0, y: 2.0),
            GainCurvePoint(x: 1.0, y: 0.5)
        ]
        let mid = AudioCompensationMath.curveGain(systemVolume: 0.5, points: points)
        XCTAssertEqual(mid, 1.25, accuracy: 0.0001)
    }

    func testCurveGainUsesBoundsOutsideRange() {
        let points = [
            GainCurvePoint(x: 0.2, y: 1.5),
            GainCurvePoint(x: 0.8, y: 0.7)
        ]
        XCTAssertEqual(AudioCompensationMath.curveGain(systemVolume: 0.0, points: points), 1.5, accuracy: 0.0001)
        XCTAssertEqual(AudioCompensationMath.curveGain(systemVolume: 1.0, points: points), 0.7, accuracy: 0.0001)
    }
}
#endif
