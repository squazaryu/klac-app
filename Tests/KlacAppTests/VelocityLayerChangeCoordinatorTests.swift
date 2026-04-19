#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class VelocityLayerChangeCoordinatorTests: XCTestCase {
    func testFirstLayerAlwaysNotifies() {
        let plan = VelocityLayerChangeCoordinator.makePlan(
            lastReportedLayer: nil,
            nextLayer: .medium
        )

        XCTAssertEqual(plan.nextLastReportedLayer, .medium)
        XCTAssertTrue(plan.shouldNotify)
    }

    func testSameLayerSkipsNotify() {
        let plan = VelocityLayerChangeCoordinator.makePlan(
            lastReportedLayer: .hard,
            nextLayer: .hard
        )

        XCTAssertEqual(plan.nextLastReportedLayer, .hard)
        XCTAssertFalse(plan.shouldNotify)
    }

    func testDifferentLayerNotifies() {
        let plan = VelocityLayerChangeCoordinator.makePlan(
            lastReportedLayer: .soft,
            nextLayer: .slam
        )

        XCTAssertEqual(plan.nextLastReportedLayer, .slam)
        XCTAssertTrue(plan.shouldNotify)
    }
}
#endif
