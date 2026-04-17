#if canImport(XCTest)
import XCTest
@testable import KlacApp

@MainActor
final class TypingMetricsServiceTests: XCTestCase {
    func testRegisterHitIncreasesCPS() {
        let service = TypingMetricsService()
        let t0: CFAbsoluteTime = 1_000

        _ = service.registerHit(now: t0)
        let snapshot = service.registerHit(now: t0 + 0.1)

        XCTAssertGreaterThan(snapshot.cps, 0.0)
        XCTAssertGreaterThan(snapshot.wpm, 0.0)
    }

    func testRecomputeDropsOldHitsOutsideWindow() {
        let service = TypingMetricsService()
        let t0: CFAbsoluteTime = 2_000

        _ = service.registerHit(now: t0)
        _ = service.registerHit(now: t0 + 0.1)
        let snapshot = service.recompute(now: t0 + 3.5)

        XCTAssertLessThan(snapshot.cps, 0.05)
    }
}
#endif
