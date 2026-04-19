#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class OutputDeviceRebuildCoordinatorTests: XCTestCase {
    func testShouldRebuildHonorsDebounceWindow() {
        let state = OutputDeviceRebuildState(lastRebuildAt: 10, graphReadyAfter: 0)

        XCTAssertFalse(OutputDeviceRebuildCoordinator.shouldRebuild(now: 10.20, state: state))
        XCTAssertTrue(OutputDeviceRebuildCoordinator.shouldRebuild(now: 10.50, state: state))
    }

    func testMarkRebuiltUpdatesStateWithSettleDelay() {
        var state = OutputDeviceRebuildState()
        OutputDeviceRebuildCoordinator.markRebuilt(
            state: &state,
            rebuildTime: 5.0,
            readyAfter: 5.2,
            settleDelay: 0.1
        )

        XCTAssertEqual(state.lastRebuildAt, 5.0, accuracy: 0.0001)
        XCTAssertEqual(state.graphReadyAfter, 5.3, accuracy: 0.0001)
    }

    func testCanPlayUsesGraphReadyAfter() {
        let state = OutputDeviceRebuildState(lastRebuildAt: 0, graphReadyAfter: 12.0)

        XCTAssertFalse(OutputDeviceRebuildCoordinator.canPlay(now: 11.9, state: state))
        XCTAssertTrue(OutputDeviceRebuildCoordinator.canPlay(now: 12.0, state: state))
    }
}
#endif
