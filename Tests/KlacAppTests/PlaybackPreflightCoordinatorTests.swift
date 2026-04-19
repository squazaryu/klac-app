#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class PlaybackPreflightCoordinatorTests: XCTestCase {
    func testCanNotPlaySkipsEverything() {
        let plan = PlaybackPreflightCoordinator.makePlan(
            canPlay: false,
            keepEngineRunning: true
        )

        XCTAssertEqual(plan, PlaybackPreflightPlan(shouldStartEngine: false, shouldContinue: false))
    }

    func testCanPlayAndKeepRunningStartsEngine() {
        let plan = PlaybackPreflightCoordinator.makePlan(
            canPlay: true,
            keepEngineRunning: true
        )

        XCTAssertEqual(plan, PlaybackPreflightPlan(shouldStartEngine: true, shouldContinue: true))
    }

    func testCanPlayAndNotKeepRunningSkipsStartButContinues() {
        let plan = PlaybackPreflightCoordinator.makePlan(
            canPlay: true,
            keepEngineRunning: false
        )

        XCTAssertEqual(plan, PlaybackPreflightPlan(shouldStartEngine: false, shouldContinue: true))
    }
}
#endif
