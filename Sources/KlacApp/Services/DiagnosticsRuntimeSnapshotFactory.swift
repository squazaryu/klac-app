import Foundation

protocol AppBuildMetadataProviding {
    func appVersion() -> String
    func buildNumber() -> String
    func buildTag() -> String
    func osVersion() -> String
}

struct SystemAppBuildMetadataProvider: AppBuildMetadataProviding {
    func appVersion() -> String {
        AppMetadataService.currentAppVersion()
    }

    func buildNumber() -> String {
        String(AppMetadataService.currentAppBuildNumber())
    }

    func buildTag() -> String {
        Bundle.main.object(forInfoDictionaryKey: "KlacBuildTag") as? String ?? "n/a"
    }

    func osVersion() -> String {
        ProcessInfo.processInfo.operatingSystemVersionString
    }
}

struct DiagnosticsRuntimeContext {
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

struct DiagnosticsRuntimeSnapshotFactory {
    private let metadataProvider: AppBuildMetadataProviding

    init(metadataProvider: AppBuildMetadataProviding = SystemAppBuildMetadataProvider()) {
        self.metadataProvider = metadataProvider
    }

    func makeSnapshot(context: DiagnosticsRuntimeContext) -> DiagnosticsRuntimeSnapshot {
        DiagnosticsRuntimeSnapshot(
            appVersion: metadataProvider.appVersion(),
            buildNumber: metadataProvider.buildNumber(),
            buildTag: metadataProvider.buildTag(),
            osVersion: metadataProvider.osVersion(),
            outputDeviceName: context.outputDeviceName,
            outputUID: context.outputUID,
            accessibilityGranted: context.accessibilityGranted,
            inputMonitoringGranted: context.inputMonitoringGranted,
            capturingKeyboard: context.capturingKeyboard,
            systemVolumeAvailable: context.systemVolumeAvailable,
            systemVolumePercent: context.systemVolumePercent,
            runtimeSettings: context.runtimeSettings,
            stressTestStatus: context.stressTestStatus
        )
    }
}

