#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class StressTestRuntimeCoordinatorTests: XCTestCase {
    func testBeginSkipsWhenAlreadyInProgress() {
        let decision = StressTestRuntimeCoordinator.begin(
            isInProgress: true,
            duration: 30,
            includeOutputRouteSimulation: true,
            currentProfile: .kalihBoxWhite
        )

        guard case let .skip(debugMessage) = decision else {
            return XCTFail("Expected skip decision")
        }
        XCTAssertEqual(debugMessage, "Stress test skipped: already in progress")
    }

    func testBeginClampsDurationAndSwitchesFromCustomPack() {
        let decision = StressTestRuntimeCoordinator.begin(
            isInProgress: false,
            duration: 2,
            includeOutputRouteSimulation: true,
            currentProfile: .customPack
        )

        guard case let .start(plan) = decision else {
            return XCTFail("Expected start decision")
        }
        XCTAssertEqual(plan.effectiveDuration, 5, accuracy: 0.0001)
        XCTAssertTrue(plan.profilePlan.switchedFromOriginal)
        XCTAssertEqual(plan.profilePlan.effectiveProfile, .kalihBoxWhite)
        XCTAssertEqual(plan.statusText, "Запущен (5с)")
    }

    func testFinishFormatting() {
        let result = StressTestResult(
            elapsed: 19.6,
            downHits: 123,
            upHits: 99,
            routeRebuilds: 1
        )

        XCTAssertEqual(
            StressTestRuntimeCoordinator.finishStatus(result: result),
            "ОК · 20с · down 123 / up 99"
        )
        XCTAssertEqual(
            StressTestRuntimeCoordinator.finishDebugMessage(result: result),
            "Stress test finished. elapsed=19.60s, down=123, up=99, routeRebuilds=1"
        )
    }
}
#endif
