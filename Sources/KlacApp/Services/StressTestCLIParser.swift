import Foundation

enum StressTestCLIParser {
    static func parseDuration(arguments: [String]) -> TimeInterval? {
        if let index = arguments.firstIndex(of: "--stress-test") {
            if index + 1 < arguments.count, let value = Double(arguments[index + 1]) {
                return value
            }
            return 20
        }
        if let inline = arguments.first(where: { $0.hasPrefix("--stress-test=") }) {
            let value = inline.replacingOccurrences(of: "--stress-test=", with: "")
            return Double(value) ?? 20
        }
        return nil
    }
}
