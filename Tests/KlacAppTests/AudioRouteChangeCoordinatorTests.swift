#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class AudioRouteChangeCoordinatorTests: XCTestCase {
    func testMakePlanSkipsRebuildWithinDebounceWindow() {
        let state = OutputDeviceRebuildState(lastRebuildAt: 10.0, graphReadyAfter: 10.0)
        let plan = AudioRouteChangeCoordinator.makePlan(
            keepEngineRunning: true,
            engineRunning: true,
            now: 10.2,
            rebuildState: state
        )

        XCTAssertEqual(plan, AudioRouteChangePlan(shouldRebuildGraph: false, shouldStartAfterRebuild: false))
    }

    func testMakePlanRebuildsAndKeepsRunningWhenNeeded() {
        let state = OutputDeviceRebuildState(lastRebuildAt: 0, graphReadyAfter: 0)
        let plan = AudioRouteChangeCoordinator.makePlan(
            keepEngineRunning: false,
            engineRunning: true,
            now: 1.0,
            rebuildState: state
        )

        XCTAssertEqual(plan, AudioRouteChangePlan(shouldRebuildGraph: true, shouldStartAfterRebuild: true))
    }

    func testMarkRebuiltUpdatesStateTimestamps() {
        var state = OutputDeviceRebuildState()
        AudioRouteChangeCoordinator.markRebuilt(state: &state, at: 12.0)

        XCTAssertEqual(state.lastRebuildAt, 12.0, accuracy: 0.0001)
        XCTAssertGreaterThan(state.graphReadyAfter, 12.0)
    }
}
#endif
