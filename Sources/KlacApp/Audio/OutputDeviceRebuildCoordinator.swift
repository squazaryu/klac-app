import Foundation

struct OutputDeviceRebuildState {
    var lastRebuildAt: CFAbsoluteTime = 0
    var graphReadyAfter: CFAbsoluteTime = 0
}

enum OutputDeviceRebuildCoordinator {
    static func shouldRebuild(
        now: CFAbsoluteTime,
        state: OutputDeviceRebuildState,
        debounceWindow: CFAbsoluteTime = 0.45
    ) -> Bool {
        now - state.lastRebuildAt >= debounceWindow
    }

    static func markRebuilt(
        state: inout OutputDeviceRebuildState,
        rebuildTime: CFAbsoluteTime,
        readyAfter: CFAbsoluteTime,
        settleDelay: CFAbsoluteTime = 0.06
    ) {
        state.lastRebuildAt = rebuildTime
        state.graphReadyAfter = readyAfter + settleDelay
    }

    static func canPlay(now: CFAbsoluteTime, state: OutputDeviceRebuildState) -> Bool {
        now >= state.graphReadyAfter
    }
}

