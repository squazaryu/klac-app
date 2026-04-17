import Foundation

struct DebugReportContext {
    let generatedAt: String
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

final class DebugLogService {
    private(set) var lines: [String] = []
    private let capacity: Int

    init(capacity: Int = 1200) {
        self.capacity = max(100, capacity)
    }

    func append(message: String, timestamp: String) -> String {
        let line = "[\(timestamp)] \(message)"
        lines.append(line)
        if lines.count > capacity {
            lines.removeFirst(lines.count - capacity)
        }
        return line
    }

    func clear() {
        lines.removeAll(keepingCapacity: true)
    }

    func preview(maxLines: Int) -> String {
        lines.suffix(max(1, maxLines)).joined(separator: "\n")
    }

    func buildReport(context: DebugReportContext, latestCrashSection: String?) -> String {
        var report: [String] = []
        report.append("Klac Debug Report")
        report.append("Generated: \(context.generatedAt)")
        report.append("App version: \(context.appVersion)")
        report.append("Build number: \(context.buildNumber)")
        report.append("Build tag: \(context.buildTag)")
        report.append("macOS: \(context.osVersion)")
        report.append("Output device: \(context.outputDeviceName)")
        report.append("Output UID: \(context.outputUID)")
        report.append("AX granted: \(context.accessibilityGranted)")
        report.append("Input Monitoring granted: \(context.inputMonitoringGranted)")
        report.append("Capturing keyboard: \(context.capturingKeyboard)")
        report.append("System volume available: \(context.systemVolumeAvailable)")
        report.append("System volume: \(Int(context.systemVolumePercent.rounded()))%")
        report.append("")
        report.append("Runtime settings:")
        report.append(contentsOf: context.runtimeSettings)
        report.append("")
        report.append("Stress test state: \(context.stressTestStatus)")
        report.append("")
        report.append("Recent debug logs:")
        report.append(contentsOf: lines)
        if let latestCrashSection {
            report.append("")
            report.append(latestCrashSection)
        }
        report.append("")
        return report.joined(separator: "\n")
    }
}
