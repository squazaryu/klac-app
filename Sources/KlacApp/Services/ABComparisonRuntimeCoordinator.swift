import Foundation

struct ABComparisonStateSource {
    let dynamicCompensationEnabled: Bool
    let typingAdaptiveEnabled: Bool
    let limiterEnabled: Bool
    let compensationStrength: Double
    let volume: Double
    let pressLevel: Double
    let releaseLevel: Double
    let spaceLevel: Double
    let lastSystemVolume: Double
}

struct ABComparisonRestoreState {
    let dynamicCompensationEnabled: Bool
    let typingAdaptiveEnabled: Bool
    let limiterEnabled: Bool
    let compensationStrength: Double
    let volume: Double
    let pressLevel: Double
    let releaseLevel: Double
    let spaceLevel: Double
    let lastSystemVolume: Double
}

struct ABComparisonBaselineState {
    let volume: Double
    let pressLevel: Double
    let releaseLevel: Double
    let spaceLevel: Double
    let compensationStrength: Double
    let lastSystemVolume: Double
}

enum ABComparisonRuntimeCoordinator {
    static func capture(_ source: ABComparisonStateSource) -> ABComparisonRestoreState {
        ABComparisonRestoreState(
            dynamicCompensationEnabled: source.dynamicCompensationEnabled,
            typingAdaptiveEnabled: source.typingAdaptiveEnabled,
            limiterEnabled: source.limiterEnabled,
            compensationStrength: source.compensationStrength,
            volume: source.volume,
            pressLevel: source.pressLevel,
            releaseLevel: source.releaseLevel,
            spaceLevel: source.spaceLevel,
            lastSystemVolume: source.lastSystemVolume
        )
    }

    static var baselineBurstState: ABComparisonBaselineState {
        ABComparisonBaselineState(
            volume: 1.0,
            pressLevel: 1.5,
            releaseLevel: 1.1,
            spaceLevel: 1.5,
            compensationStrength: 2.0,
            lastSystemVolume: 0.1
        )
    }
}
