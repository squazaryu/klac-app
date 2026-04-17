import Foundation

struct ParsedVersion {
    let core: [Int]
    let suffix: String
    let embeddedBuild: Int
}

enum KlacVersioning {
    static func normalizedVersion(fromTag tag: String) -> String {
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.hasPrefix("v") {
            return String(trimmed.dropFirst())
        }
        return trimmed
    }

    static func parseVersion(_ raw: String) -> ParsedVersion {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let parts = trimmed.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: false)
        let corePart = String(parts.first ?? "")
        let suffix = parts.count > 1 ? String(parts[1]) : ""
        let core = corePart.split(separator: ".").map { Int($0.filter(\.isNumber)) ?? 0 }
        let build = firstIntMatch(in: suffix, pattern: #"b([0-9]{1,14})"#) ?? 0
        return ParsedVersion(core: core, suffix: suffix, embeddedBuild: build)
    }

    static func isVersion(_ candidate: String, newerThan current: String, currentBuild: Int) -> Bool {
        let a = parseVersion(candidate)
        let b = parseVersion(current)
        let count = max(a.core.count, b.core.count)
        for i in 0 ..< count {
            let x = i < a.core.count ? a.core[i] : 0
            let y = i < b.core.count ? b.core[i] : 0
            if x != y { return x > y }
        }

        if a.suffix != b.suffix {
            if !a.suffix.isEmpty && b.suffix.isEmpty { return true }
            if a.suffix.isEmpty && !b.suffix.isEmpty { return true }
            return a.suffix.compare(b.suffix, options: .numeric) == .orderedDescending
        }

        if a.embeddedBuild > 0 {
            return a.embeddedBuild > max(currentBuild, b.embeddedBuild)
        }
        return false
    }

    private static func firstIntMatch(in text: String, pattern: String) -> Int? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let ns = text as NSString
        let range = NSRange(location: 0, length: ns.length)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              match.numberOfRanges > 1 else { return nil }
        let captured = ns.substring(with: match.range(at: 1))
        return Int(captured)
    }
}
