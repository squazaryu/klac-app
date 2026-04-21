import Foundation

struct KeyboardCaptureStartDependencies {
    let refreshStatus: () -> PermissionsStatus
    let startAudio: () -> Void
    let startInputCapture: () -> Bool
}

struct KeyboardCaptureRefreshDependencies {
    let refreshStatus: (Bool) -> PermissionsStatus
    let startAudio: () -> Void
    let startInputCapture: () -> Bool
}

struct KeyboardCaptureStopDependencies {
    let stopInputCapture: () -> Void
    let stopAudio: () -> Void
}

struct KeyboardCaptureRefreshOutcome {
    let accessibilityGranted: Bool
    let inputMonitoringGranted: Bool
    let capturingKeyboard: Bool
}

enum KeyboardCaptureRuntimeCoordinator {
    static func start(dependencies: KeyboardCaptureStartDependencies) -> KeyboardCaptureRefreshOutcome {
        let status = dependencies.refreshStatus()
        dependencies.startAudio()
        let capturing = dependencies.startInputCapture()
        return KeyboardCaptureRefreshOutcome(
            accessibilityGranted: status.accessibilityGranted,
            inputMonitoringGranted: status.inputMonitoringGranted,
            capturingKeyboard: capturing
        )
    }

    static func refresh(
        promptIfNeeded: Bool,
        isEnabled: Bool,
        currentCapturingKeyboard: Bool,
        dependencies: KeyboardCaptureRefreshDependencies
    ) -> KeyboardCaptureRefreshOutcome {
        let status = dependencies.refreshStatus(promptIfNeeded)
        let capturing: Bool
        if isEnabled {
            dependencies.startAudio()
            capturing = dependencies.startInputCapture()
        } else {
            // Preserve previous state when runtime is disabled to avoid
            // altering capture flag semantics outside explicit start/stop paths.
            capturing = currentCapturingKeyboard
        }
        return KeyboardCaptureRefreshOutcome(
            accessibilityGranted: status.accessibilityGranted,
            inputMonitoringGranted: status.inputMonitoringGranted,
            capturingKeyboard: capturing
        )
    }

    static func stop(dependencies: KeyboardCaptureStopDependencies) {
        dependencies.stopInputCapture()
        dependencies.stopAudio()
    }
}
