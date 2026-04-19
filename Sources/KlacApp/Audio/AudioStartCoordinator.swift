import Foundation

struct AudioStartPlan: Equatable {
    let shouldStartEngine: Bool
    let shouldPlayPlayer: Bool
}

enum AudioStartCoordinator {
    static func makePlan(engineRunning: Bool, playerPlaying: Bool) -> AudioStartPlan {
        AudioStartPlan(
            shouldStartEngine: !engineRunning,
            shouldPlayPlayer: !playerPlaying
        )
    }
}
