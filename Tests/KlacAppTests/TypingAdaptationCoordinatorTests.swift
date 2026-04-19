#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class TypingAdaptationCoordinatorTests: XCTestCase {
    func testReturnsOneWhenStrictNormalizationEnabled() {
        let gain = TypingAdaptationCoordinator.resolveGain(
            TypingAdaptationInput(
                strictVolumeNormalizationEnabled: true,
                typingAdaptiveEnabled: true,
                typingCPS: 10,
                personalBaselineCPS: 5
            )
        )
        XCTAssertEqual(gain, 1.0, accuracy: 0.0001)
    }

    func testReturnsOneWhenTypingAdaptationDisabled() {
        let gain = TypingAdaptationCoordinator.resolveGain(
            TypingAdaptationInput(
                strictVolumeNormalizationEnabled: false,
                typingAdaptiveEnabled: false,
                typingCPS: 10,
                personalBaselineCPS: 5
            )
        )
        XCTAssertEqual(gain, 1.0, accuracy: 0.0001)
    }

    func testAdaptiveGainIncreasesWithTypingSpeedAndClamps() {
        let low = TypingAdaptationCoordinator.resolveGain(
            TypingAdaptationInput(
                strictVolumeNormalizationEnabled: false,
                typingAdaptiveEnabled: true,
                typingCPS: 1.5,
                personalBaselineCPS: 5
            )
        )
        let high = TypingAdaptationCoordinator.resolveGain(
            TypingAdaptationInput(
                strictVolumeNormalizationEnabled: false,
                typingAdaptiveEnabled: true,
                typingCPS: 100,
                personalBaselineCPS: 5
            )
        )
        XCTAssertGreaterThan(high, low)
        XCTAssertLessThanOrEqual(high, 2.5)
        XCTAssertGreaterThanOrEqual(low, 1.0)
    }
}
#endif
