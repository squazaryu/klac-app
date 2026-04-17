#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class TypingMetricsEngineTests: XCTestCase {
    func testRegisterHitUpdatesCpsAndWpm() {
        var engine = TypingMetricsEngine()
        _ = engine.registerHit(now: 10.0)
        _ = engine.registerHit(now: 10.2)
        let snapshot = engine.registerHit(now: 10.4)

        XCTAssertEqual(snapshot.cps, 1.0, accuracy: 0.0001)
        XCTAssertEqual(snapshot.wpm, 12.0, accuracy: 0.0001)
    }

    func testRecomputeDropsOldTimestampsOutsideWindow() {
        var engine = TypingMetricsEngine()
        _ = engine.registerHit(now: 1.0)
        _ = engine.registerHit(now: 1.1)
        let snapshot = engine.recompute(now: 5.0)

        XCTAssertEqual(snapshot.cps, 0.0, accuracy: 0.0001)
        XCTAssertEqual(snapshot.wpm, 0.0, accuracy: 0.0001)
    }

    func testPersonalBaselineMovesTowardCurrentCps() {
        var engine = TypingMetricsEngine()
        let initial = engine.recompute(now: 0).personalBaselineCPS
        for idx in 0 ..< 30 {
            _ = engine.registerHit(now: Double(idx) * 0.05)
        }
        let adjusted = engine.recompute(now: 1.6).personalBaselineCPS
        XCTAssertGreaterThan(adjusted, initial)
    }
}
#endif
