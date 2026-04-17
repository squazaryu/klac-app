import Foundation

@MainActor
final class TypingMetricsService {
    private var engine = TypingMetricsEngine()
    private var decayTimer: Timer?
    private var decayCallback: ((TypingMetricsSnapshot) -> Void)?

    var personalBaselineCPS: Double {
        engine.personalBaselineCPS
    }

    deinit {
        decayTimer?.invalidate()
    }

    func registerHit(now: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()) -> TypingMetricsSnapshot {
        engine.registerHit(now: now)
    }

    func recompute(now: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()) -> TypingMetricsSnapshot {
        engine.recompute(now: now)
    }

    func setDecayMonitoringEnabled(
        _ enabled: Bool,
        interval: TimeInterval = 0.2,
        onSnapshot: @escaping (TypingMetricsSnapshot) -> Void
    ) {
        decayCallback = onSnapshot
        if enabled {
            if decayTimer == nil {
                startDecayMonitoring(interval: interval)
            }
        } else {
            stopDecayMonitoring()
        }
    }

    private func startDecayMonitoring(interval: TimeInterval) {
        decayTimer?.invalidate()
        decayTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let snapshot = self.recompute()
                self.decayCallback?(snapshot)
            }
        }
    }

    private func stopDecayMonitoring() {
        decayTimer?.invalidate()
        decayTimer = nil
    }
}
