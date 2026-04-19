#if canImport(XCTest)
import Foundation
import XCTest
@testable import KlacApp

final class ProfileSettingsTransferCoordinatorTests: XCTestCase {
    func testExportSettingsWritesDataAndReturnsSuccess() {
        let targetURL = URL(fileURLWithPath: "/tmp/profile.json")
        let dialogs = MockFileDialogService(profileExportURL: targetURL)
        let io = MockFileIO()
        let coordinator = ProfileSettingsTransferCoordinator(
            transferService: .init(),
            fileDialogs: dialogs,
            fileIO: io
        )
        let state = ProfileSettingsState(
            selectedProfile: .kalihBoxWhite,
            volume: 0.7,
            variation: 0.3,
            playKeyUp: true,
            pressLevel: 1.0,
            releaseLevel: 0.6,
            spaceLevel: 1.1
        )

        let result = coordinator.exportSettings(from: state)

        XCTAssertEqual(result, .success(path: targetURL.path))
        XCTAssertEqual(io.lastWriteURL, targetURL)
        XCTAssertNotNil(io.lastWriteData)
    }

    func testImportSettingsReadsAndReturnsDecodedState() throws {
        let importURL = URL(fileURLWithPath: "/tmp/import.json")
        let dialogs = MockFileDialogService(profileImportURL: importURL)
        let io = MockFileIO()
        io.readData = try ProfileSettingsTransferService().exportData(
            from: ProfileSettingsState(
                selectedProfile: .mechvibesEGOreo,
                volume: 0.55,
                variation: 0.22,
                playKeyUp: false,
                pressLevel: 0.95,
                releaseLevel: 0.5,
                spaceLevel: 1.0
            )
        )
        let coordinator = ProfileSettingsTransferCoordinator(
            transferService: .init(),
            fileDialogs: dialogs,
            fileIO: io
        )

        let (result, imported) = coordinator.importSettings(fallbackProfile: .kalihBoxWhite)

        XCTAssertEqual(result, .success(path: importURL.path))
        XCTAssertEqual(io.lastReadURL, importURL)
        XCTAssertEqual(imported?.selectedProfile, .mechvibesEGOreo)
        XCTAssertEqual(imported?.volume, 0.55, accuracy: 0.0001)
    }

    func testImportSettingsCancelledReturnsCancelled() {
        let coordinator = ProfileSettingsTransferCoordinator(
            transferService: .init(),
            fileDialogs: MockFileDialogService(),
            fileIO: MockFileIO()
        )

        let (result, imported) = coordinator.importSettings(fallbackProfile: .kalihBoxWhite)

        XCTAssertEqual(result, .cancelled)
        XCTAssertNil(imported)
    }
}

private final class MockFileDialogService: FileDialogPresenting {
    var profileExportURL: URL?
    var profileImportURL: URL?
    var debugExportURL: URL?

    init(profileExportURL: URL? = nil, profileImportURL: URL? = nil, debugExportURL: URL? = nil) {
        self.profileExportURL = profileExportURL
        self.profileImportURL = profileImportURL
        self.debugExportURL = debugExportURL
    }

    func pickProfileExportURL() -> URL? { profileExportURL }
    func pickProfileImportURL() -> URL? { profileImportURL }
    func pickDebugLogExportURL(defaultFileName _: String) -> URL? { debugExportURL }
}

private final class MockFileIO: FileReadWriting {
    var readData: Data = Data()
    var lastWriteData: Data?
    var lastWriteURL: URL?
    var lastReadURL: URL?

    func write(_ data: Data, to url: URL) throws {
        lastWriteData = data
        lastWriteURL = url
    }

    func read(from url: URL) throws -> Data {
        lastReadURL = url
        return readData
    }
}
#endif
