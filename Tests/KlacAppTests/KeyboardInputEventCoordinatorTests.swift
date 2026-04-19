#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class KeyboardInputEventCoordinatorTests: XCTestCase {
    func testDisabledServiceSuppressesAllActions() {
        let plan = KeyboardInputEventCoordinator.makePlan(.init(
            isEnabled: false,
            playKeyUp: true,
            type: .down,
            keyCode: 12,
            isAutorepeat: false
        ))

        XCTAssertEqual(plan, .init(shouldTrackTyping: false, shouldPlayDown: false, shouldPlayUp: false))
    }

    func testDownEventWithoutAutorepeatTracksAndPlaysDown() {
        let plan = KeyboardInputEventCoordinator.makePlan(.init(
            isEnabled: true,
            playKeyUp: true,
            type: .down,
            keyCode: 12,
            isAutorepeat: false
        ))

        XCTAssertEqual(plan, .init(shouldTrackTyping: true, shouldPlayDown: true, shouldPlayUp: false))
    }

    func testDownEventWithAutorepeatSkipsTrackAndDown() {
        let plan = KeyboardInputEventCoordinator.makePlan(.init(
            isEnabled: true,
            playKeyUp: true,
            type: .down,
            keyCode: 12,
            isAutorepeat: true
        ))

        XCTAssertEqual(plan, .init(shouldTrackTyping: false, shouldPlayDown: false, shouldPlayUp: false))
    }

    func testUpEventRespectsPlayKeyUpFlag() {
        let enabledPlan = KeyboardInputEventCoordinator.makePlan(.init(
            isEnabled: true,
            playKeyUp: true,
            type: .up,
            keyCode: 12,
            isAutorepeat: false
        ))
        let disabledPlan = KeyboardInputEventCoordinator.makePlan(.init(
            isEnabled: true,
            playKeyUp: false,
            type: .up,
            keyCode: 12,
            isAutorepeat: false
        ))

        XCTAssertEqual(enabledPlan, .init(shouldTrackTyping: false, shouldPlayDown: false, shouldPlayUp: true))
        XCTAssertEqual(disabledPlan, .init(shouldTrackTyping: false, shouldPlayDown: false, shouldPlayUp: false))
    }
}
#endif
