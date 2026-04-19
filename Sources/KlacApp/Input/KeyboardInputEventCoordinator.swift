import Foundation

struct KeyboardInputEventContext {
    let isEnabled: Bool
    let playKeyUp: Bool
    let type: KeyEventType
    let keyCode: Int
    let isAutorepeat: Bool
}

struct KeyboardInputEventPlan: Equatable {
    let shouldTrackTyping: Bool
    let shouldPlayDown: Bool
    let shouldPlayUp: Bool
}

enum KeyboardInputEventCoordinator {
    static func makePlan(_ context: KeyboardInputEventContext) -> KeyboardInputEventPlan {
        guard context.isEnabled else {
            return KeyboardInputEventPlan(
                shouldTrackTyping: false,
                shouldPlayDown: false,
                shouldPlayUp: false
            )
        }

        switch context.type {
        case .down:
            let playDown = !context.isAutorepeat
            return KeyboardInputEventPlan(
                shouldTrackTyping: playDown,
                shouldPlayDown: playDown,
                shouldPlayUp: false
            )
        case .up:
            return KeyboardInputEventPlan(
                shouldTrackTyping: false,
                shouldPlayDown: false,
                shouldPlayUp: context.playKeyUp
            )
        }
    }
}
