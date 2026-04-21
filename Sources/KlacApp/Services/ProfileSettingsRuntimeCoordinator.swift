import Foundation

struct ProfileSettingsExportSource {
    let selectedProfile: SoundProfile
    let volume: Double
    let variation: Double
    let playKeyUp: Bool
    let pressLevel: Double
    let releaseLevel: Double
    let spaceLevel: Double
}

struct ProfileSettingsRuntimeDependencies {
    let exportSettings: (ProfileSettingsState) -> ProfileSettingsTransferResult
    let importSettings: (SoundProfile) -> (ProfileSettingsTransferResult, ProfileSettingsState?)
    let applyImportedSettings: (ProfileSettingsState) -> Void
    let recordDebug: (String) -> Void
}

enum ProfileSettingsRuntimeCoordinator {
    static func makeExportState(from source: ProfileSettingsExportSource) -> ProfileSettingsState {
        ProfileSettingsState(
            selectedProfile: source.selectedProfile,
            volume: source.volume,
            variation: source.variation,
            playKeyUp: source.playKeyUp,
            pressLevel: source.pressLevel,
            releaseLevel: source.releaseLevel,
            spaceLevel: source.spaceLevel
        )
    }

    static func runExport(
        source: ProfileSettingsExportSource,
        dependencies: ProfileSettingsRuntimeDependencies
    ) {
        let state = makeExportState(from: source)
        let result = dependencies.exportSettings(state)
        RuntimeResultLoggingCoordinator.handleProfileExportResult(result, recordDebug: dependencies.recordDebug)
    }

    static func runImport(
        fallbackProfile: SoundProfile,
        dependencies: ProfileSettingsRuntimeDependencies
    ) {
        let (result, importedState) = dependencies.importSettings(fallbackProfile)
        RuntimeResultLoggingCoordinator.handleProfileImportResult(
            result,
            importedState: importedState,
            applyImportedSettings: dependencies.applyImportedSettings,
            recordDebug: dependencies.recordDebug
        )
    }
}
