#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class AccessRecoveryPlanCoordinatorTests: XCTestCase {
    func testPlanContainsExpectedTCCServices() {
        let plan = AccessRecoveryPlanCoordinator.makePlan()
        XCTAssertEqual(plan.tccServicesToReset, ["Accessibility", "ListenEvent"])
    }

    func testPlanHintsAreNonEmpty() {
        let plan = AccessRecoveryPlanCoordinator.makePlan()
        XCTAssertFalse(plan.postResetHint.isEmpty)
        XCTAssertFalse(plan.wizardHint.isEmpty)
        XCTAssertFalse(plan.restartFailureHint.isEmpty)
    }
}
#endif
