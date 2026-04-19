import Foundation

struct TypingAdaptationInput {
    let strictVolumeNormalizationEnabled: Bool
    let typingAdaptiveEnabled: Bool
    let typingCPS: Double
    let personalBaselineCPS: Double
}

enum TypingAdaptationCoordinator {
    static func resolveGain(_ input: TypingAdaptationInput) -> Double {
        if input.strictVolumeNormalizationEnabled || !input.typingAdaptiveEnabled {
            return 1.0
        }
        let target = max(2.5, input.personalBaselineCPS * 1.1)
        let normalized = (input.typingCPS / target).clamped(to: 0.0 ... 1.6)
        let gain = 1.0 + 0.25 + normalized * 0.95
        return gain.clamped(to: 1.0 ... 2.5)
    }
}

