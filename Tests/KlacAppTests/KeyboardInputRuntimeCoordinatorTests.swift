#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class KeyboardInputRuntimeCoordinatorTests: XCTestCase {
    func testDownEventTriggersTrackAndDown() {
        var calls: [String] = []
        KeyboardInputRuntimeCoordinator.handle(
            context: .init(
                isEnabled: true,
                playKeyUp: true,
                type: .down,
                keyCode: 12,
                isAutorepeat: false
            ),
            dependencies: .init(
                trackTypingHit: { calls.append("track") },
                playDown: { key, repeatFlag in calls.append("down:\(key):\(repeatFlag)") },
                playUp: { key in calls.append("up:\(key)") }
            )
        )

        XCTAssertEqual(calls, ["track", "down:12:false"])
    }

    func testUpEventTriggersUpWhenEnabled() {
        var calls: [String] = []
        KeyboardInputRuntimeCoordinator.handle(
            context: .init(
                isEnabled: true,
                playKeyUp: true,
                type: .up,
                keyCode: 36,
                isAutorepeat: false
            ),
            dependencies: .init(
                trackTypingHit: { calls.append("track") },
                playDown: { key, repeatFlag in calls.append("down:\(key):\(repeatFlag)") },
                playUp: { key in calls.append("up:\(key)") }
            )
        )

        XCTAssertEqual(calls, ["up:36"])
    }

    func testDisabledContextTriggersNoActions() {
        var calls: [String] = []
        KeyboardInputRuntimeCoordinator.handle(
            context: .init(
                isEnabled: false,
                playKeyUp: true,
                type: .down,
                keyCode: 49,
                isAutorepeat: false
            ),
            dependencies: .init(
                trackTypingHit: { calls.append("track") },
                playDown: { key, repeatFlag in calls.append("down:\(key):\(repeatFlag)") },
                playUp: { key in calls.append("up:\(key)") }
            )
        )

        XCTAssertTrue(calls.isEmpty)
    }
}
#endif
