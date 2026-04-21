import Foundation

struct KeyboardInputRuntimeDependencies {
    let trackTypingHit: () -> Void
    let playDown: (Int, Bool) -> Void
    let playUp: (Int) -> Void
}

enum KeyboardInputRuntimeCoordinator {
    static func handle(
        context: KeyboardInputEventContext,
        dependencies: KeyboardInputRuntimeDependencies
    ) {
        let plan = KeyboardInputEventCoordinator.makePlan(context)
        if plan.shouldTrackTyping {
            dependencies.trackTypingHit()
        }
        if plan.shouldPlayDown {
            dependencies.playDown(context.keyCode, context.isAutorepeat)
        }
        if plan.shouldPlayUp {
            dependencies.playUp(context.keyCode)
        }
    }
}
