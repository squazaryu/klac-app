import Foundation

struct PlaybackPreflightPlan: Equatable {
    let shouldStartEngine: Bool
    let shouldContinue: Bool
}

enum PlaybackPreflightCoordinator {
    static func makePlan(canPlay: Bool, keepEngineRunning: Bool) -> PlaybackPreflightPlan {
        guard canPlay else {
            return PlaybackPreflightPlan(shouldStartEngine: false, shouldContinue: false)
        }
        return PlaybackPreflightPlan(
            shouldStartEngine: keepEngineRunning,
            shouldContinue: true
        )
    }
}
