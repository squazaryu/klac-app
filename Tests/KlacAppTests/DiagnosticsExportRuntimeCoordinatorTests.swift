#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class DiagnosticsExportRuntimeCoordinatorTests: XCTestCase {
    func testExportBuildsSnapshotAndDelegatesToDebugExportCoordinator() {
        let debugLog = DebugLogService(capacity: 10)
        _ = debugLog.append(message: "line-1", timestamp: "t")
        let exporter = MockDebugLogExportCoordinator()
        let snapshotFactory = DiagnosticsRuntimeSnapshotFactory(metadataProvider: MockBuildMetadata())
        let source = DiagnosticsExportRuntimeSource(
            outputDeviceName: "USB DAC",
            outputUID: "dev-123",
            accessibilityGranted: true,
            inputMonitoringGranted: true,
            capturingKeyboard: true,
            systemVolumeAvailable: true,
            systemVolumePercent: 52,
            runtimeSettings: ["volume=0.7"],
            stressTestStatus: "ok"
        )

        let result = DiagnosticsExportRuntimeCoordinator.export(
            source: source,
            diagnosticsSnapshotFactory: snapshotFactory,
            debugLogService: debugLog,
            debugLogExportCoordinator: exporter
        )

        XCTAssertEqual(result, .success(path: "/tmp/diag.log"))
        XCTAssertEqual(exporter.calls, 1)
        XCTAssertEqual(exporter.lastSnapshot?.appVersion, "2.1.6")
        XCTAssertEqual(exporter.lastSnapshot?.buildNumber, "202604210001")
        XCTAssertEqual(exporter.lastSnapshot?.outputDeviceName, "USB DAC")
        XCTAssertEqual(exporter.lastSnapshot?.systemVolumePercent, 52, accuracy: 0.0001)
        XCTAssertTrue(exporter.lastDefaultFileName?.hasPrefix("klac-debug-") == true)
    }
}

private struct MockBuildMetadata: AppBuildMetadataProviding {
    func appVersion() -> String { "2.1.6" }
    func buildNumber() -> String { "202604210001" }
    func buildTag() -> String { "dev" }
    func osVersion() -> String { "macOS-test" }
}

private final class MockDebugLogExportCoordinator: DebugLogExportCoordinating {
    var calls = 0
    var lastSnapshot: DiagnosticsRuntimeSnapshot?
    var lastDefaultFileName: String?

    func exportDebugLog(
        runtimeSnapshot: DiagnosticsRuntimeSnapshot,
        debugLogService _: DebugLogService,
        defaultFileName: String
    ) -> DebugLogExportResult {
        calls += 1
        lastSnapshot = runtimeSnapshot
        lastDefaultFileName = defaultFileName
        return .success(path: "/tmp/diag.log")
    }
}
#endif
