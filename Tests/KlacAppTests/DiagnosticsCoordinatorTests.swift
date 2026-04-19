#if canImport(XCTest)
import Foundation
import XCTest
@testable import KlacApp

final class DiagnosticsCoordinatorTests: XCTestCase {
    func testBuildReportContainsMetadataAndRuntimeSections() {
        let fs = MockDiagnosticsFileSystem()
        let coordinator = DiagnosticsCoordinator(filesystem: fs, timestampFormatter: fixedFormatter())
        let logService = DebugLogService()
        _ = logService.append(message: "line", timestamp: "2026-01-01T00:00:00Z")
        let snapshot = DiagnosticsRuntimeSnapshot(
            appVersion: "2.1.4",
            buildNumber: "100",
            buildTag: "dev",
            osVersion: "macOS",
            outputDeviceName: "Headphones",
            outputUID: "uid",
            accessibilityGranted: true,
            inputMonitoringGranted: true,
            capturingKeyboard: true,
            systemVolumeAvailable: true,
            systemVolumePercent: 42,
            runtimeSettings: ["- profile=kalih"],
            stressTestStatus: "idle"
        )

        let report = coordinator.buildReport(runtimeSnapshot: snapshot, debugLogService: logService)

        XCTAssertTrue(report.contains("Klac Debug Report"))
        XCTAssertTrue(report.contains("App version: 2.1.4"))
        XCTAssertTrue(report.contains("Output device: Headphones"))
        XCTAssertTrue(report.contains("Runtime settings:"))
        XCTAssertTrue(report.contains("- profile=kalih"))
    }

    func testLatestCrashSelectionChoosesNewestFile() {
        let older = URL(fileURLWithPath: "/tmp/KlacApp-old.crash")
        let newer = URL(fileURLWithPath: "/tmp/KlacApp-new.ips")
        let fs = MockDiagnosticsFileSystem(
            entries: [older, newer],
            modificationDates: [
                older: Date(timeIntervalSince1970: 1000),
                newer: Date(timeIntervalSince1970: 2000),
            ],
            dataByURL: [
                newer: Data("new-crash".utf8),
            ]
        )
        let coordinator = DiagnosticsCoordinator(filesystem: fs, timestampFormatter: fixedFormatter())

        let section = coordinator.latestCrashReportSection()

        XCTAssertNotNil(section)
        XCTAssertTrue(section?.contains(newer.path) == true)
        XCTAssertTrue(section?.contains("new-crash") == true)
    }

    func testLatestCrashSectionHandlesMissingFilesGracefully() {
        let fs = MockDiagnosticsFileSystem(entries: [], modificationDates: [:], dataByURL: [:])
        let coordinator = DiagnosticsCoordinator(filesystem: fs, timestampFormatter: fixedFormatter())

        XCTAssertNil(coordinator.latestCrashReportSection())
    }

    func testLatestCrashSectionFallsBackForUndecodableContent() {
        let file = URL(fileURLWithPath: "/tmp/KlacApp-bad.crash")
        let fs = MockDiagnosticsFileSystem(
            entries: [file],
            modificationDates: [file: Date()],
            dataByURL: [file: Data([0xFF, 0xD8, 0xFF])]
        )
        let coordinator = DiagnosticsCoordinator(filesystem: fs, timestampFormatter: fixedFormatter())

        let section = coordinator.latestCrashReportSection()

        XCTAssertNotNil(section)
        XCTAssertTrue(section?.contains("unable to decode file") == true)
    }

    private func fixedFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }
}

private struct MockDiagnosticsFileSystem: DiagnosticsFileSystem {
    var entries: [URL] = []
    var modificationDates: [URL: Date] = [:]
    var dataByURL: [URL: Data] = [:]

    func contentsOfDirectory(
        at _: URL,
        includingPropertiesForKeys _: [URLResourceKey],
        options _: FileManager.DirectoryEnumerationOptions
    ) throws -> [URL] {
        entries
    }

    func resourceValues(forKeys _: Set<URLResourceKey>, at url: URL) throws -> URLResourceValues {
        var values = URLResourceValues()
        values.contentModificationDate = modificationDates[url]
        return values
    }

    func data(at url: URL) throws -> Data {
        if let data = dataByURL[url] {
            return data
        }
        throw NSError(domain: "MockDiagnosticsFileSystem", code: 1)
    }
}
#endif
