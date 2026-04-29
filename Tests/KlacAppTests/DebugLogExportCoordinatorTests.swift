#if canImport(XCTest)
import Foundation
import XCTest
@testable import KlacApp

final class DebugLogExportCoordinatorTests: XCTestCase {
    func testExportCancelledWhenNoTargetSelected() {
        let coordinator = DebugLogExportCoordinator(
            diagnosticsCoordinator: DiagnosticsCoordinator(filesystem: EmptyDiagnosticsFileSystem()),
            fileDialogs: DebugDialogStub(exportURL: nil),
            fileIO: DebugFileIOStub()
        )

        let result = coordinator.exportDebugLog(
            runtimeSnapshot: makeSnapshot(),
            debugLogService: DebugLogService(),
            defaultFileName: "debug.log"
        )

        XCTAssertEqual(result, .cancelled)
    }

    func testExportWritesReportAndReturnsSuccess() {
        let target = URL(fileURLWithPath: "/tmp/klac-debug.log")
        let io = DebugFileIOStub()
        let coordinator = DebugLogExportCoordinator(
            diagnosticsCoordinator: DiagnosticsCoordinator(filesystem: EmptyDiagnosticsFileSystem()),
            fileDialogs: DebugDialogStub(exportURL: target),
            fileIO: io
        )
        let log = DebugLogService()
        _ = log.append(message: "test-line")

        let result = coordinator.exportDebugLog(
            runtimeSnapshot: makeSnapshot(),
            debugLogService: log,
            defaultFileName: "debug.log"
        )

        XCTAssertEqual(result, .success(path: target.path))
        XCTAssertEqual(io.lastWriteURL, target)
        XCTAssertNotNil(io.lastWriteData)
    }

    private func makeSnapshot() -> DiagnosticsRuntimeSnapshot {
        DiagnosticsRuntimeSnapshot(
            appVersion: "2.1.6",
            buildNumber: "1",
            buildTag: "dev",
            osVersion: "macOS",
            outputDeviceName: "Speakers",
            outputUID: "uid",
            accessibilityGranted: true,
            inputMonitoringGranted: true,
            capturingKeyboard: true,
            systemVolumeAvailable: true,
            systemVolumePercent: 50,
            runtimeSettings: ["- sample=true"],
            stressTestStatus: "idle"
        )
    }
}

private struct DebugDialogStub: FileDialogPresenting {
    let exportURL: URL?
    func pickProfileExportURL() -> URL? { nil }
    func pickProfileImportURL() -> URL? { nil }
    func pickDebugLogExportURL(defaultFileName _: String) -> URL? { exportURL }
}

private final class DebugFileIOStub: FileReadWriting {
    var lastWriteData: Data?
    var lastWriteURL: URL?

    func write(_ data: Data, to url: URL) throws {
        lastWriteData = data
        lastWriteURL = url
    }

    func read(from _: URL) throws -> Data {
        Data()
    }
}

private struct EmptyDiagnosticsFileSystem: DiagnosticsFileSystem {
    func contentsOfDirectory(
        at _: URL,
        includingPropertiesForKeys _: [URLResourceKey],
        options _: FileManager.DirectoryEnumerationOptions
    ) throws -> [URL] {
        []
    }

    func resourceValues(forKeys _: Set<URLResourceKey>, at _: URL) throws -> URLResourceValues {
        URLResourceValues()
    }

    func data(at _: URL) throws -> Data {
        Data()
    }
}
#endif
