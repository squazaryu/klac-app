import Foundation

struct OutputDeviceTransitionContext {
    let perDeviceSoundProfileEnabled: Bool
    let previousDeviceUID: String
    let newDeviceUID: String
    let isInitialProbe: Bool
    let hasPersistedPrimarySettings: Bool
}

struct OutputDeviceTransitionBeginPlan {
    let shouldSavePreviousSnapshot: Bool
    let shouldAttemptRestoreSnapshot: Bool
}

enum OutputDeviceTransitionPresetAction: Equatable {
    case applyAutoPreset
    case markSavedSettings
    case markDeviceProfile
}

struct OutputDeviceTransitionFinalizePlan: Equatable {
    let presetAction: OutputDeviceTransitionPresetAction
    let shouldSaveNewSnapshot: Bool
    let statusLabel: String?
}

enum OutputDeviceTransitionCoordinator {
    static func beginPlan(for context: OutputDeviceTransitionContext) -> OutputDeviceTransitionBeginPlan {
        OutputDeviceTransitionBeginPlan(
            shouldSavePreviousSnapshot: context.perDeviceSoundProfileEnabled && !context.previousDeviceUID.isEmpty,
            shouldAttemptRestoreSnapshot: context.perDeviceSoundProfileEnabled && !context.newDeviceUID.isEmpty
        )
    }

    static func finalizePlan(
        for context: OutputDeviceTransitionContext,
        restoredSnapshot: Bool
    ) -> OutputDeviceTransitionFinalizePlan {
        if restoredSnapshot {
            return OutputDeviceTransitionFinalizePlan(
                presetAction: .markDeviceProfile,
                shouldSaveNewSnapshot: false,
                statusLabel: "Профиль устройства"
            )
        }
        let shouldApplyAutoPreset = SystemAudioPollCoordinator.shouldApplyAutoPreset(
            isInitialProbe: context.isInitialProbe,
            hasPersistedPrimarySettings: context.hasPersistedPrimarySettings,
            restoredSnapshot: restoredSnapshot
        )
        if shouldApplyAutoPreset {
            return OutputDeviceTransitionFinalizePlan(
                presetAction: .applyAutoPreset,
                shouldSaveNewSnapshot: context.perDeviceSoundProfileEnabled && !context.newDeviceUID.isEmpty,
                statusLabel: nil
            )
        }
        return OutputDeviceTransitionFinalizePlan(
            presetAction: .markSavedSettings,
            shouldSaveNewSnapshot: context.perDeviceSoundProfileEnabled && !context.newDeviceUID.isEmpty,
            statusLabel: "Сохраненные настройки"
        )
    }
}
