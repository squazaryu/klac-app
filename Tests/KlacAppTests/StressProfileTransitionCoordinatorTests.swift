#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class StressProfileTransitionCoordinatorTests: XCTestCase {
    func testPrepareSwitchesCustomPackToFallback() {
        let plan = StressProfileTransitionCoordinator.prepare(
            currentProfile: .customPack,
            fallbackProfile: .kalihBoxWhite
        )

        XCTAssertEqual(plan.effectiveProfile, .kalihBoxWhite)
        XCTAssertTrue(plan.switchedFromOriginal)
    }

    func testPrepareKeepsNonCustomProfile() {
        let plan = StressProfileTransitionCoordinator.prepare(
            currentProfile: .mechvibesEGOreo,
            fallbackProfile: .kalihBoxWhite
        )

        XCTAssertEqual(plan.effectiveProfile, .mechvibesEGOreo)
        XCTAssertFalse(plan.switchedFromOriginal)
    }

    func testShouldRestoreOriginalFollowsSwitchFlag() {
        XCTAssertTrue(StressProfileTransitionCoordinator.shouldRestoreOriginal(switchedFromOriginal: true))
        XCTAssertFalse(StressProfileTransitionCoordinator.shouldRestoreOriginal(switchedFromOriginal: false))
    }
}
#endif
