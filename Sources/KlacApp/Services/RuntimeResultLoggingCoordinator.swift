import Foundation

enum RuntimeResultLoggingCoordinator {
    static func handleProfileExportResult(
        _ result: ProfileSettingsTransferResult,
        recordDebug: (String) -> Void
    ) {
        switch result {
        case .cancelled:
            break
        case let .success(path):
            recordDebug("Settings exported: \(path)")
        case let .failure(message):
            recordDebug("Failed to export settings: \(message)")
        }
    }

    static func handleProfileImportResult(
        _ result: ProfileSettingsTransferResult,
        importedState: ProfileSettingsState?,
        applyImportedSettings: (ProfileSettingsState) -> Void,
        recordDebug: (String) -> Void
    ) {
        switch result {
        case .cancelled:
            break
        case let .success(path):
            if let importedState {
                applyImportedSettings(importedState)
            }
            recordDebug("Settings imported: \(path)")
        case let .failure(message):
            recordDebug("Failed to import settings: \(message)")
        }
    }

    static func handleDebugLogExportResult(
        _ result: DebugLogExportResult,
        recordDebug: (String) -> Void
    ) {
        switch result {
        case .cancelled:
            break
        case let .success(path):
            recordDebug("Debug log exported: \(path)")
        case let .failure(message):
            recordDebug("Failed to export debug log: \(message)")
        }
    }
}
