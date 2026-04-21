#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class RuntimeResultLoggingCoordinatorTests: XCTestCase {
    func testProfileExportSuccessWritesDebugMessage() {
        var logs: [String] = []

        RuntimeResultLoggingCoordinator.handleProfileExportResult(.success(path: "/tmp/out.json")) {
            logs.append($0)
        }

        XCTAssertEqual(logs, ["Settings exported: /tmp/out.json"])
    }

    func testProfileImportSuccessAppliesStateAndLogs() {
        var logs: [String] = []
        var applied = false
        let state = ProfileSettingsState(
            selectedProfile: .kalihBoxWhite,
            volume: 0.7,
            variation: 0.3,
            playKeyUp: true,
            pressLevel: 1.0,
            releaseLevel: 0.65,
            spaceLevel: 1.1
        )

        RuntimeResultLoggingCoordinator.handleProfileImportResult(
            .success(path: "/tmp/in.json"),
            importedState: state,
            applyImportedSettings: { _ in applied = true },
            recordDebug: { logs.append($0) }
        )

        XCTAssertTrue(applied)
        XCTAssertEqual(logs, ["Settings imported: /tmp/in.json"])
    }

    func testDebugLogExportFailureWritesError() {
        var logs: [String] = []

        RuntimeResultLoggingCoordinator.handleDebugLogExportResult(.failure(message: "disk full")) {
            logs.append($0)
        }

        XCTAssertEqual(logs, ["Failed to export debug log: disk full"])
    }
}
#endif
