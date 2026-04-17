#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class SamplePickerTests: XCTestCase {
    func testPickReturnsSingleElementForSinglePool() {
        let picker = SamplePicker<String>()
        let value = picker.pick(from: [42], group: "g")
        XCTAssertEqual(value, 42)
    }

    func testPickReturnsElementFromPool() {
        let picker = SamplePicker<String>()
        let pool = [1, 2, 3]
        for _ in 0 ..< 20 {
            let value = picker.pick(from: pool, group: "g")
            XCTAssertNotNil(value)
            XCTAssertTrue(pool.contains(value!))
        }
    }
}
#endif
