import Foundation

struct ABComparisonScenarioDependencies {
    let applyBaselineForBurst: () -> Void
    let setDynamicCompensationEnabled: (Bool) -> Void
    let setLimiterEnabled: (Bool) -> Void
    let setTypingAdaptiveEnabled: (Bool) -> Void
    let updateDynamicCompensation: () -> Void
    let playStressBurst: () async -> Void
    let playTestSound: () -> Void
    let sleep: (UInt64) async -> Void
}

enum ABComparisonScenarioCoordinator {
    static func run(
        feature: KlacABFeature,
        dependencies: ABComparisonScenarioDependencies
    ) async {
        switch feature {
        case .core:
            dependencies.applyBaselineForBurst()
            dependencies.updateDynamicCompensation()
            dependencies.setDynamicCompensationEnabled(false)
            dependencies.setLimiterEnabled(false)
            await dependencies.playStressBurst()
            await dependencies.sleep(220_000_000)
            dependencies.setDynamicCompensationEnabled(true)
            dependencies.setLimiterEnabled(true)
            dependencies.updateDynamicCompensation()
            await dependencies.playStressBurst()

        case .compensation:
            dependencies.applyBaselineForBurst()
            dependencies.updateDynamicCompensation()
            dependencies.setDynamicCompensationEnabled(false)
            await dependencies.playStressBurst()
            await dependencies.sleep(220_000_000)
            dependencies.setDynamicCompensationEnabled(true)
            dependencies.updateDynamicCompensation()
            await dependencies.playStressBurst()

        case .adaptation:
            dependencies.setTypingAdaptiveEnabled(false)
            dependencies.playTestSound()
            await dependencies.sleep(350_000_000)
            dependencies.setTypingAdaptiveEnabled(true)
            dependencies.playTestSound()

        case .limiter:
            dependencies.applyBaselineForBurst()
            dependencies.setLimiterEnabled(false)
            await dependencies.playStressBurst()
            await dependencies.sleep(220_000_000)
            dependencies.setLimiterEnabled(true)
            await dependencies.playStressBurst()
        }
    }
}
