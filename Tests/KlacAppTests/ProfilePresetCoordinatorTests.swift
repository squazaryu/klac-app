#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class ProfilePresetCoordinatorTests: XCTestCase {
    func testKnownProfileReturnsPresetAndLabel() {
        let decision = ProfilePresetCoordinator.decide(for: .g915Tactile)

        XCTAssertNotNil(decision.settings)
        XCTAssertFalse(decision.label.isEmpty)
        XCTAssertNotEqual(decision.label, "Базовый пресет")
    }

    func testCustomPackReturnsBaselineLabelWithoutSettings() {
        let decision = ProfilePresetCoordinator.decide(for: .customPack)

        XCTAssertNil(decision.settings)
        XCTAssertEqual(decision.label, "Базовый пресет")
    }
}
#endif
