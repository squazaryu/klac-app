import Foundation

protocol DiagnosticsFileSystem {
    func contentsOfDirectory(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey],
        options: FileManager.DirectoryEnumerationOptions
    ) throws -> [URL]
    func resourceValues(forKeys keys: Set<URLResourceKey>, at url: URL) throws -> URLResourceValues
    func data(at url: URL) throws -> Data
}

struct LocalDiagnosticsFileSystem: DiagnosticsFileSystem {
    func contentsOfDirectory(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey],
        options: FileManager.DirectoryEnumerationOptions
    ) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: keys,
            options: options
        )
    }

    func resourceValues(forKeys keys: Set<URLResourceKey>, at url: URL) throws -> URLResourceValues {
        try url.resourceValues(forKeys: keys)
    }

    func data(at url: URL) throws -> Data {
        try Data(contentsOf: url)
    }
}

struct DiagnosticsRuntimeSnapshot {
    let appVersion: String
    let buildNumber: String
    let buildTag: String
    let osVersion: String
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

struct DiagnosticsCoordinator {
    private let filesystem: DiagnosticsFileSystem
    private let timestampFormatter: ISO8601DateFormatter

    init(
        filesystem: DiagnosticsFileSystem = LocalDiagnosticsFileSystem(),
        timestampFormatter: ISO8601DateFormatter = {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return formatter
        }()
    ) {
        self.filesystem = filesystem
        self.timestampFormatter = timestampFormatter
    }

    func buildReport(runtimeSnapshot: DiagnosticsRuntimeSnapshot, debugLogService: DebugLogService) -> String {
        let context = DebugReportContext(
            generatedAt: timestampFormatter.string(from: Date()),
            appVersion: runtimeSnapshot.appVersion,
            buildNumber: runtimeSnapshot.buildNumber,
            buildTag: runtimeSnapshot.buildTag,
            osVersion: runtimeSnapshot.osVersion,
            outputDeviceName: runtimeSnapshot.outputDeviceName,
            outputUID: runtimeSnapshot.outputUID,
            accessibilityGranted: runtimeSnapshot.accessibilityGranted,
            inputMonitoringGranted: runtimeSnapshot.inputMonitoringGranted,
            capturingKeyboard: runtimeSnapshot.capturingKeyboard,
            systemVolumeAvailable: runtimeSnapshot.systemVolumeAvailable,
            systemVolumePercent: runtimeSnapshot.systemVolumePercent,
            runtimeSettings: runtimeSnapshot.runtimeSettings,
            stressTestStatus: runtimeSnapshot.stressTestStatus
        )
        return debugLogService.buildReport(
            context: context,
            latestCrashSection: latestCrashReportSection()
        )
    }

    func latestCrashReportSection() -> String? {
        let diagnosticsRoot = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/DiagnosticReports", isDirectory: true)
        guard let latest = latestCrashReportFile(in: diagnosticsRoot) else {
            return nil
        }
        guard let data = try? filesystem.data(at: latest),
              let text = String(data: data, encoding: .utf8) else {
            return "Latest crash report: \(latest.path)\n(unable to decode file)"
        }
        let preview = text.split(separator: "\n").prefix(120).joined(separator: "\n")
        return """
        Latest crash report: \(latest.path)
        ----
        \(preview)
        ----
        """
    }

    private func latestCrashReportFile(in directory: URL) -> URL? {
        guard let entries = try? filesystem.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }
        let candidates = entries.filter { url in
            let name = url.lastPathComponent.lowercased()
            return (name.hasPrefix("klac") || name.hasPrefix("klacapp")) &&
                (name.hasSuffix(".crash") || name.hasSuffix(".ips"))
        }

        return candidates.max { lhs, rhs in
            let lhsDate = (try? filesystem.resourceValues(forKeys: [.contentModificationDateKey], at: lhs).contentModificationDate) ?? .distantPast
            let rhsDate = (try? filesystem.resourceValues(forKeys: [.contentModificationDateKey], at: rhs).contentModificationDate) ?? .distantPast
            return lhsDate < rhsDate
        }
    }
}
