import Foundation

struct AudioRouteChangePlan: Equatable {
    let shouldRebuildGraph: Bool
    let shouldStartAfterRebuild: Bool
}

enum AudioRouteChangeCoordinator {
    static func makePlan(
        keepEngineRunning: Bool,
        engineRunning: Bool,
        now: CFAbsoluteTime,
        rebuildState: OutputDeviceRebuildState
    ) -> AudioRouteChangePlan {
        let shouldRebuild = OutputDeviceRebuildCoordinator.shouldRebuild(
            now: now,
            state: rebuildState
        )
        guard shouldRebuild else {
            return AudioRouteChangePlan(
                shouldRebuildGraph: false,
                shouldStartAfterRebuild: false
            )
        }
        return AudioRouteChangePlan(
            shouldRebuildGraph: true,
            shouldStartAfterRebuild: keepEngineRunning || engineRunning
        )
    }

    static func markRebuilt(state: inout OutputDeviceRebuildState, at now: CFAbsoluteTime) {
        OutputDeviceRebuildCoordinator.markRebuilt(
            state: &state,
            rebuildTime: now,
            readyAfter: now
        )
    }
}
