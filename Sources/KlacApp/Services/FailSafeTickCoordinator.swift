import Foundation

struct FailSafeTickPlan: Equatable {
    let shouldAttemptKeyboardRecovery: Bool
    let shouldRunAudioEngineFailSafe: Bool
}

enum FailSafeTickCoordinator {
    static func makePlan(
        isEnabled: Bool,
        currentlyCapturingKeyboard: Bool,
        accessibilityGranted: Bool,
        inputMonitoringGranted: Bool
    ) -> FailSafeTickPlan {
        let shouldAttemptKeyboardRecovery =
            isEnabled &&
            !currentlyCapturingKeyboard &&
            accessibilityGranted &&
            inputMonitoringGranted

        return FailSafeTickPlan(
            shouldAttemptKeyboardRecovery: shouldAttemptKeyboardRecovery,
            shouldRunAudioEngineFailSafe: isEnabled
        )
    }
}

