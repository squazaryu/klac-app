import Foundation

enum StressTestRuntimeDecision {
    case skip(debugMessage: String)
    case start(StressTestRuntimeStartPlan)
}

struct StressTestRuntimeStartPlan {
    let effectiveDuration: TimeInterval
    let originalProfile: SoundProfile
    let profilePlan: StressProfileTransitionPlan
    let statusText: String
    let startDebugMessage: String
    let switchDebugMessage: String?
}

enum StressTestRuntimeCoordinator {
    static func begin(
        isInProgress: Bool,
        duration: TimeInterval,
        includeOutputRouteSimulation: Bool,
        currentProfile: SoundProfile,
        fallbackProfile: SoundProfile = .kalihBoxWhite
    ) -> StressTestRuntimeDecision {
        guard !isInProgress else {
            return .skip(debugMessage: "Stress test skipped: already in progress")
        }

        let effectiveDuration = duration.clamped(to: 5 ... 180)
        let profilePlan = StressProfileTransitionCoordinator.prepare(
            currentProfile: currentProfile,
            fallbackProfile: fallbackProfile
        )
        let switchDebugMessage = profilePlan.switchedFromOriginal
            ? "Stress test switched profile customPack -> kalihBoxWhite (to guarantee playable samples)"
            : nil

        return .start(
            StressTestRuntimeStartPlan(
                effectiveDuration: effectiveDuration,
                originalProfile: currentProfile,
                profilePlan: profilePlan,
                statusText: "Запущен (\(Int(effectiveDuration))с)",
                startDebugMessage: "Stress test started. duration=\(Int(effectiveDuration))s, routeSimulation=\(includeOutputRouteSimulation)",
                switchDebugMessage: switchDebugMessage
            )
        )
    }

    static func shouldRestoreOriginalProfile(
        switchedFromOriginal: Bool,
        selectedProfile: SoundProfile,
        originalProfile: SoundProfile
    ) -> Bool {
        StressProfileTransitionCoordinator.shouldRestoreOriginal(switchedFromOriginal: switchedFromOriginal) &&
            selectedProfile != originalProfile
    }

    static func finishStatus(result: StressTestResult) -> String {
        "ОК · \(Int(result.elapsed.rounded()))с · down \(result.downHits) / up \(result.upHits)"
    }

    static func finishDebugMessage(result: StressTestResult) -> String {
        "Stress test finished. elapsed=\(String(format: "%.2f", result.elapsed))s, " +
            "down=\(result.downHits), up=\(result.upHits), routeRebuilds=\(result.routeRebuilds)"
    }
}
