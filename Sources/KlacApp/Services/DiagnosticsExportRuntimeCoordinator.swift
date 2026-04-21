import Foundation

struct DiagnosticsExportRuntimeSource {
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

enum DiagnosticsExportRuntimeCoordinator {
    static func export(
        source: DiagnosticsExportRuntimeSource,
        diagnosticsSnapshotFactory: DiagnosticsRuntimeSnapshotFactory,
        debugLogService: DebugLogService,
        debugLogExportCoordinator: any DebugLogExportCoordinating
    ) -> DebugLogExportResult {
        let runtimeContext = DiagnosticsRuntimeContextMapper.map(DiagnosticsRuntimeContextInput(
            outputDeviceName: source.outputDeviceName,
            outputUID: source.outputUID,
            accessibilityGranted: source.accessibilityGranted,
            inputMonitoringGranted: source.inputMonitoringGranted,
            capturingKeyboard: source.capturingKeyboard,
            systemVolumeAvailable: source.systemVolumeAvailable,
            systemVolumePercent: source.systemVolumePercent,
            runtimeSettings: source.runtimeSettings,
            stressTestStatus: source.stressTestStatus
        ))
        let runtimeSnapshot = diagnosticsSnapshotFactory.makeSnapshot(context: runtimeContext)
        return debugLogExportCoordinator.exportDebugLog(
            runtimeSnapshot: runtimeSnapshot,
            debugLogService: debugLogService,
            defaultFileName: "klac-debug-\(DiagnosticsTimestampProvider.fileTimestamp()).log"
        )
    }
}
