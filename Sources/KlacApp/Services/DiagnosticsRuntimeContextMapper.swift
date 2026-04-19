import Foundation

struct DiagnosticsRuntimeContextInput {
    let outputDeviceName: String
    let outputUID: String
    let accessibilityGranted: Bool
    let inputMonitoringGranted: Bool
    let capturingKeyboard: Bool
    let systemVolumeAvailable: Bool
    let systemVolumePercent: Double
    let runtimeSettings: [String]
    let stressTestStatus: String
}

enum DiagnosticsRuntimeContextMapper {
    static func map(_ input: DiagnosticsRuntimeContextInput) -> DiagnosticsRuntimeContext {
        DiagnosticsRuntimeContext(
            outputDeviceName: input.outputDeviceName,
            outputUID: input.outputUID.isEmpty ? "n/a" : input.outputUID,
            accessibilityGranted: input.accessibilityGranted,
            inputMonitoringGranted: input.inputMonitoringGranted,
            capturingKeyboard: input.capturingKeyboard,
            systemVolumeAvailable: input.systemVolumeAvailable,
            systemVolumePercent: input.systemVolumePercent,
            runtimeSettings: input.runtimeSettings,
            stressTestStatus: input.stressTestStatus
        )
    }
}
