import Foundation

struct FailSafeRuntimeInput {
    let now: CFAbsoluteTime
    let resetThreshold: CFAbsoluteTime
    let isEnabled: Bool
    let currentlyCapturingKeyboard: Bool
    let accessibilityGranted: Bool
    let inputMonitoringGranted: Bool
}

struct FailSafeRuntimeDependencies {
    let resetStuckPollIfNeeded: (CFAbsoluteTime, CFAbsoluteTime) -> Bool
    let recoverKeyboardCaptureIfNeeded: (Bool, Bool, Bool, Bool) -> Bool
    let runAudioEngineFailSafe: () -> Void
}

struct FailSafeRuntimeOutcome {
    let didResetStuckPoll: Bool
    let recoveredKeyboardCapture: Bool?
}

enum FailSafeRuntimeCoordinator {
    static func run(
        input: FailSafeRuntimeInput,
        dependencies: FailSafeRuntimeDependencies
    ) -> FailSafeRuntimeOutcome {
        let didResetStuckPoll = dependencies.resetStuckPollIfNeeded(input.now, input.resetThreshold)

        let plan = FailSafeTickCoordinator.makePlan(
            isEnabled: input.isEnabled,
            currentlyCapturingKeyboard: input.currentlyCapturingKeyboard,
            accessibilityGranted: input.accessibilityGranted,
            inputMonitoringGranted: input.inputMonitoringGranted
        )

        let recoveredKeyboardCapture: Bool?
        if plan.shouldAttemptKeyboardRecovery {
            recoveredKeyboardCapture = dependencies.recoverKeyboardCaptureIfNeeded(
                input.isEnabled,
                input.accessibilityGranted,
                input.inputMonitoringGranted,
                input.currentlyCapturingKeyboard
            )
        } else {
            recoveredKeyboardCapture = nil
        }

        if plan.shouldRunAudioEngineFailSafe {
            dependencies.runAudioEngineFailSafe()
        }

        return FailSafeRuntimeOutcome(
            didResetStuckPoll: didResetStuckPoll,
            recoveredKeyboardCapture: recoveredKeyboardCapture
        )
    }
}
