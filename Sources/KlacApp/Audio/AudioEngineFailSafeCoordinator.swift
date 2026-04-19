import Foundation

enum AudioEngineFailSafeAction: Equatable {
    case none
    case restartEngine
    case resumePlayer
}

enum AudioEngineFailSafeCoordinator {
    static func decide(
        keepEngineRunning: Bool,
        engineRunning: Bool,
        playerPlaying: Bool,
        hadRecentPlayback: Bool
    ) -> AudioEngineFailSafeAction {
        guard keepEngineRunning else { return .none }
        if !engineRunning {
            return .restartEngine
        }
        if !playerPlaying, hadRecentPlayback {
            return .resumePlayer
        }
        return .none
    }
}

