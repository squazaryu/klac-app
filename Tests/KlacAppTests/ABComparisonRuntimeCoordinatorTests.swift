#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class ABComparisonRuntimeCoordinatorTests: XCTestCase {
    func testCaptureCopiesAllFields() {
        let source = ABComparisonStateSource(
            dynamicCompensationEnabled: true,
            typingAdaptiveEnabled: false,
            limiterEnabled: true,
            compensationStrength: 1.8,
            volume: 0.73,
            pressLevel: 1.2,
            releaseLevel: 0.66,
            spaceLevel: 1.1,
            lastSystemVolume: 0.42
        )

        let captured = ABComparisonRuntimeCoordinator.capture(source)

        XCTAssertEqual(captured.dynamicCompensationEnabled, true)
        XCTAssertEqual(captured.typingAdaptiveEnabled, false)
        XCTAssertEqual(captured.limiterEnabled, true)
        XCTAssertEqual(captured.compensationStrength, 1.8, accuracy: 0.0001)
        XCTAssertEqual(captured.volume, 0.73, accuracy: 0.0001)
        XCTAssertEqual(captured.pressLevel, 1.2, accuracy: 0.0001)
        XCTAssertEqual(captured.releaseLevel, 0.66, accuracy: 0.0001)
        XCTAssertEqual(captured.spaceLevel, 1.1, accuracy: 0.0001)
        XCTAssertEqual(captured.lastSystemVolume, 0.42, accuracy: 0.0001)
    }

    func testBaselineBurstStateValuesAreStable() {
        let baseline = ABComparisonRuntimeCoordinator.baselineBurstState

        XCTAssertEqual(baseline.volume, 1.0, accuracy: 0.0001)
        XCTAssertEqual(baseline.pressLevel, 1.5, accuracy: 0.0001)
        XCTAssertEqual(baseline.releaseLevel, 1.1, accuracy: 0.0001)
        XCTAssertEqual(baseline.spaceLevel, 1.5, accuracy: 0.0001)
        XCTAssertEqual(baseline.compensationStrength, 2.0, accuracy: 0.0001)
        XCTAssertEqual(baseline.lastSystemVolume, 0.1, accuracy: 0.0001)
    }
}
#endif
