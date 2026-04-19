#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class CompensationCurveCoordinatorTests: XCTestCase {
    func testCurveGainReturnsReasonableValueInsideRange() {
        let gain = CompensationCurveCoordinator.curveGain(
            systemVolume: 0.6,
            macLow: 0.30,
            kbdLow: 1.60,
            macLowMid: 0.45,
            kbdLowMid: 1.30,
            macMid: 0.60,
            kbdMid: 1.00,
            macHighMid: 0.80,
            kbdHighMid: 0.70,
            macHigh: 1.00,
            kbdHigh: 0.45
        )

        XCTAssertGreaterThan(gain, 0.2)
        XCTAssertLessThan(gain, 4.0)
    }

    func testStrictCurveGainScalesToTargetAt100() {
        let target = 0.5
        let gainAt100 = CompensationCurveCoordinator.strictCurveGain(
            systemVolume: 1.0,
            targetAt100: target,
            macLow: 0.30,
            kbdLow: 1.60,
            macLowMid: 0.45,
            kbdLowMid: 1.30,
            macMid: 0.60,
            kbdMid: 1.00,
            macHighMid: 0.80,
            kbdHighMid: 0.70,
            macHigh: 1.00,
            kbdHigh: 0.45
        )

        XCTAssertEqual(gainAt100, target, accuracy: 0.0001)
    }

    func testStrictCurveGainClampsTargetRange() {
        let low = CompensationCurveCoordinator.strictCurveGain(
            systemVolume: 1.0,
            targetAt100: 0.01,
            macLow: 0.30,
            kbdLow: 1.60,
            macLowMid: 0.45,
            kbdLowMid: 1.30,
            macMid: 0.60,
            kbdMid: 1.00,
            macHighMid: 0.80,
            kbdHighMid: 0.70,
            macHigh: 1.00,
            kbdHigh: 0.45
        )
        let high = CompensationCurveCoordinator.strictCurveGain(
            systemVolume: 1.0,
            targetAt100: 9.99,
            macLow: 0.30,
            kbdLow: 1.60,
            macLowMid: 0.45,
            kbdLowMid: 1.30,
            macMid: 0.60,
            kbdMid: 1.00,
            macHighMid: 0.80,
            kbdHighMid: 0.70,
            macHigh: 1.00,
            kbdHigh: 0.45
        )

        XCTAssertEqual(low, 0.20, accuracy: 0.0001)
        XCTAssertEqual(high, 1.20, accuracy: 0.0001)
    }
}
#endif
