import Foundation

struct StressProfileTransitionPlan: Equatable {
    let effectiveProfile: SoundProfile
    let switchedFromOriginal: Bool
}

enum StressProfileTransitionCoordinator {
    static func prepare(currentProfile: SoundProfile, fallbackProfile: SoundProfile) -> StressProfileTransitionPlan {
        if currentProfile == .customPack {
            return StressProfileTransitionPlan(effectiveProfile: fallbackProfile, switchedFromOriginal: true)
        }
        return StressProfileTransitionPlan(effectiveProfile: currentProfile, switchedFromOriginal: false)
    }

    static func shouldRestoreOriginal(switchedFromOriginal: Bool) -> Bool {
        switchedFromOriginal
    }
}

