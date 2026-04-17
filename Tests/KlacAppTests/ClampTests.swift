#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class ClampTests: XCTestCase {
    func testDoubleClampBounds() {
        XCTAssertEqual((-1.0).clamped(to: 0.0 ... 1.0), 0.0, accuracy: 0.0001)
        XCTAssertEqual((2.0).clamped(to: 0.0 ... 1.0), 1.0, accuracy: 0.0001)
        XCTAssertEqual((0.6).clamped(to: 0.0 ... 1.0), 0.6, accuracy: 0.0001)
    }

    func testFloatClampBounds() {
        XCTAssertEqual(Float(-2).clamped(to: 0 ... 1), 0, accuracy: 0.0001)
        XCTAssertEqual(Float(2).clamped(to: 0 ... 1), 1, accuracy: 0.0001)
        XCTAssertEqual(Float(0.2).clamped(to: 0 ... 1), 0.2, accuracy: 0.0001)
    }
}
#endif
