import Foundation

enum DebugLogExportResult: Equatable {
    case cancelled
    case success(path: String)
    case failure(message: String)
}

protocol DebugLogExportCoordinating {
    func exportDebugLog(
        runtimeSnapshot: DiagnosticsRuntimeSnapshot,
        debugLogService: DebugLogService,
        defaultFileName: String
    ) -> DebugLogExportResult
}

struct DebugLogExportCoordinator: DebugLogExportCoordinating {
    private let diagnosticsCoordinator: DiagnosticsCoordinator
    private let fileDialogs: FileDialogPresenting
    private let fileIO: FileReadWriting

    init(
        diagnosticsCoordinator: DiagnosticsCoordinator = .init(),
        fileDialogs: FileDialogPresenting = SystemFileDialogService(),
        fileIO: FileReadWriting = FileSystemReadWriter()
    ) {
        self.diagnosticsCoordinator = diagnosticsCoordinator
        self.fileDialogs = fileDialogs
        self.fileIO = fileIO
    }

    func exportDebugLog(
        runtimeSnapshot: DiagnosticsRuntimeSnapshot,
        debugLogService: DebugLogService,
        defaultFileName: String
    ) -> DebugLogExportResult {
        guard let url = fileDialogs.pickDebugLogExportURL(defaultFileName: defaultFileName) else {
            return .cancelled
        }
        let report = diagnosticsCoordinator.buildReport(
            runtimeSnapshot: runtimeSnapshot,
            debugLogService: debugLogService
        )
        do {
            try fileIO.write(Data(report.utf8), to: url)
            return .success(path: url.path)
        } catch {
            return .failure(message: error.localizedDescription)
        }
    }
}

