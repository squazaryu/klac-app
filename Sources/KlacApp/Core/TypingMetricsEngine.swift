import Foundation

struct TypingMetricsSnapshot {
    let cps: Double
    let wpm: Double
    let personalBaselineCPS: Double
}

struct TypingMetricsEngine {
    private(set) var timestamps: [CFAbsoluteTime] = []
    private(set) var personalBaselineCPS: Double = 3.0

    mutating func registerHit(now: CFAbsoluteTime) -> TypingMetricsSnapshot {
        timestamps.append(now)
        return recompute(now: now)
    }

    mutating func recompute(now: CFAbsoluteTime) -> TypingMetricsSnapshot {
        let windowStart = now - 3.0
        timestamps.removeAll { $0 < windowStart }
        let cps = Double(timestamps.count) / 3.0
        let wpm = cps * 12.0
        personalBaselineCPS = personalBaselineCPS * 0.985 + cps * 0.015
        return TypingMetricsSnapshot(cps: cps, wpm: wpm, personalBaselineCPS: personalBaselineCPS)
    }
}
