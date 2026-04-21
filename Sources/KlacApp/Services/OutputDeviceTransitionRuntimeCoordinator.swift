import Foundation

struct OutputDeviceTransitionRuntimeDependencies {
    let saveSnapshot: (String) -> Void
    let loadBoost: (String) -> Double
    let rebuildAudioGraph: () -> Void
    let restoreSnapshot: (String) -> Bool
    let applyAutoPreset: (String, String) -> Void
}

struct OutputDeviceTransitionRuntimeOutcome {
    let currentOutputDeviceBoost: Double
    let statusLabel: String?
}

enum OutputDeviceTransitionRuntimeCoordinator {
    static func handle(
        result: SystemAudioPollResult,
        perDeviceSoundProfileEnabled: Bool,
        hasPersistedPrimarySettings: Bool,
        dependencies: OutputDeviceTransitionRuntimeDependencies
    ) -> OutputDeviceTransitionRuntimeOutcome {
        let deviceUID = result.deviceUID
        let deviceName = result.deviceName
        let transitionContext = OutputDeviceTransitionContext(
            perDeviceSoundProfileEnabled: perDeviceSoundProfileEnabled,
            previousDeviceUID: result.previousDeviceUID,
            newDeviceUID: deviceUID,
            isInitialProbe: result.isInitialProbe,
            hasPersistedPrimarySettings: hasPersistedPrimarySettings
        )
        let beginPlan = OutputDeviceTransitionCoordinator.beginPlan(for: transitionContext)
        if beginPlan.shouldSavePreviousSnapshot {
            dependencies.saveSnapshot(result.previousDeviceUID)
        }

        let boost = dependencies.loadBoost(deviceUID)
        dependencies.rebuildAudioGraph()

        let restored = beginPlan.shouldAttemptRestoreSnapshot
            ? dependencies.restoreSnapshot(deviceUID)
            : false

        let finalizePlan = OutputDeviceTransitionCoordinator.finalizePlan(
            for: transitionContext,
            restoredSnapshot: restored
        )
        if finalizePlan.presetAction == .applyAutoPreset {
            dependencies.applyAutoPreset(deviceUID, deviceName)
        }
        if finalizePlan.shouldSaveNewSnapshot {
            dependencies.saveSnapshot(deviceUID)
        }

        return OutputDeviceTransitionRuntimeOutcome(
            currentOutputDeviceBoost: boost,
            statusLabel: finalizePlan.statusLabel
        )
    }
}
