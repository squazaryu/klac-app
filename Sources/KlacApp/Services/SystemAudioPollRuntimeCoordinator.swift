import Foundation

struct SystemAudioPollRuntimeDependencies {
    let handleOutputDeviceTransition: (SystemAudioPollResult) -> Void
    let rebuildAudioGraphAfterAvailabilityChange: () -> Void
    let updateDynamicCompensation: () -> Void
}

struct SystemAudioPollRuntimeOutcome {
    let state: SystemAudioPollState
    let didRebuildForAvailabilityChange: Bool
}

enum SystemAudioPollRuntimeCoordinator {
    static func handle(
        payload: SystemAudioPollPayload,
        state: SystemAudioPollState,
        dependencies: SystemAudioPollRuntimeDependencies
    ) -> SystemAudioPollRuntimeOutcome {
        let result = SystemAudioPollCoordinator.process(payload: payload, state: state)

        if result.deviceChanged {
            dependencies.handleOutputDeviceTransition(result)
        }

        let didRebuildForAvailabilityChange = result.availabilityChanged && !result.deviceChanged
        if didRebuildForAvailabilityChange {
            dependencies.rebuildAudioGraphAfterAvailabilityChange()
        }

        if result.volumeChanged || result.deviceChanged || result.availabilityChanged {
            dependencies.updateDynamicCompensation()
        }

        return SystemAudioPollRuntimeOutcome(
            state: result.state,
            didRebuildForAvailabilityChange: didRebuildForAvailabilityChange
        )
    }
}
