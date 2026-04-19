import Foundation

enum DiagnosticsTimestampProvider {
    private static let debugFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static func debugTimestamp(date: Date = Date()) -> String {
        debugFormatter.string(from: date)
    }

    static func fileTimestamp(date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: date)
    }
}
