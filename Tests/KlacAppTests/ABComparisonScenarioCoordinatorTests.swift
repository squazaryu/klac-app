#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class ABComparisonScenarioCoordinatorTests: XCTestCase {
    func testCoreScenarioSequence() async {
        let recorder = ScenarioRecorder()

        await ABComparisonScenarioCoordinator.run(
            feature: .core,
            dependencies: recorder.dependencies()
        )

        XCTAssertEqual(
            recorder.events,
            [
                "baseline",
                "update",
                "dynamic:false",
                "limiter:false",
                "burst",
                "sleep:220000000",
                "dynamic:true",
                "limiter:true",
                "update",
                "burst",
            ]
        )
    }

    func testAdaptationScenarioSequence() async {
        let recorder = ScenarioRecorder()

        await ABComparisonScenarioCoordinator.run(
            feature: .adaptation,
            dependencies: recorder.dependencies()
        )

        XCTAssertEqual(
            recorder.events,
            [
                "typing:false",
                "test",
                "sleep:350000000",
                "typing:true",
                "test",
            ]
        )
    }
}

private final class ScenarioRecorder {
    var events: [String] = []

    func dependencies() -> ABComparisonScenarioDependencies {
        ABComparisonScenarioDependencies(
            applyBaselineForBurst: { [weak self] in self?.events.append("baseline") },
            setDynamicCompensationEnabled: { [weak self] value in self?.events.append("dynamic:\(value)") },
            setLimiterEnabled: { [weak self] value in self?.events.append("limiter:\(value)") },
            setTypingAdaptiveEnabled: { [weak self] value in self?.events.append("typing:\(value)") },
            updateDynamicCompensation: { [weak self] in self?.events.append("update") },
            playStressBurst: { [weak self] in self?.events.append("burst") },
            playTestSound: { [weak self] in self?.events.append("test") },
            sleep: { [weak self] ns in self?.events.append("sleep:\(ns)") }
        )
    }
}
#endif
