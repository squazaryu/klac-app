#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class AudioStartCoordinatorTests: XCTestCase {
    func testMakePlanStartsBothWhenIdle() {
        let plan = AudioStartCoordinator.makePlan(engineRunning: false, playerPlaying: false)
        XCTAssertEqual(plan, AudioStartPlan(shouldStartEngine: true, shouldPlayPlayer: true))
    }

    func testMakePlanStartsOnlyPlayerWhenEngineAlreadyRunning() {
        let plan = AudioStartCoordinator.makePlan(engineRunning: true, playerPlaying: false)
        XCTAssertEqual(plan, AudioStartPlan(shouldStartEngine: false, shouldPlayPlayer: true))
    }

    func testMakePlanNoopsWhenBothAlreadyRunning() {
        let plan = AudioStartCoordinator.makePlan(engineRunning: true, playerPlaying: true)
        XCTAssertEqual(plan, AudioStartPlan(shouldStartEngine: false, shouldPlayPlayer: false))
    }
}
#endif
