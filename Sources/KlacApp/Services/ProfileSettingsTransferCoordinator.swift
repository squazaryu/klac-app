import Foundation

enum ProfileSettingsTransferResult: Equatable {
    case cancelled
    case success(path: String)
    case failure(message: String)
}

protocol ProfileSettingsTransferCoordinating {
    func exportSettings(from state: ProfileSettingsState) -> ProfileSettingsTransferResult
    func importSettings(fallbackProfile: SoundProfile) -> (ProfileSettingsTransferResult, ProfileSettingsState?)
}

struct ProfileSettingsTransferCoordinator: ProfileSettingsTransferCoordinating {
    private let transferService: ProfileSettingsTransferService
    private let fileDialogs: FileDialogPresenting
    private let fileIO: FileReadWriting

    init(
        transferService: ProfileSettingsTransferService = .init(),
        fileDialogs: FileDialogPresenting = SystemFileDialogService(),
        fileIO: FileReadWriting = FileSystemReadWriter()
    ) {
        self.transferService = transferService
        self.fileDialogs = fileDialogs
        self.fileIO = fileIO
    }

    func exportSettings(from state: ProfileSettingsState) -> ProfileSettingsTransferResult {
        guard let url = fileDialogs.pickProfileExportURL() else { return .cancelled }
        do {
            let data = try transferService.exportData(from: state)
            try fileIO.write(data, to: url)
            return .success(path: url.path)
        } catch {
            return .failure(message: error.localizedDescription)
        }
    }

    func importSettings(fallbackProfile: SoundProfile) -> (ProfileSettingsTransferResult, ProfileSettingsState?) {
        guard let url = fileDialogs.pickProfileImportURL() else {
            return (.cancelled, nil)
        }
        do {
            let data = try fileIO.read(from: url)
            let state = try transferService.importState(from: data, fallbackProfile: fallbackProfile)
            return (.success(path: url.path), state)
        } catch {
            return (.failure(message: error.localizedDescription), nil)
        }
    }
}
