#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class KeyCodeClassifierTests: XCTestCase {
    func testSpaceKeyCodeMapsToSpaceGroup() {
        XCTAssertEqual(KeyCodeClassifier.resolveKeyGroup(for: 49), .space)
    }

    func testEnterKeyCodesMapToEnterGroup() {
        XCTAssertEqual(KeyCodeClassifier.resolveKeyGroup(for: 36), .enter)
        XCTAssertEqual(KeyCodeClassifier.resolveKeyGroup(for: 76), .enter)
    }

    func testDeleteKeyCodesMapToDeleteGroup() {
        XCTAssertEqual(KeyCodeClassifier.resolveKeyGroup(for: 51), .delete)
        XCTAssertEqual(KeyCodeClassifier.resolveKeyGroup(for: 117), .delete)
    }

    func testArrowKeyCodesMapToArrowGroup() {
        XCTAssertEqual(KeyCodeClassifier.resolveKeyGroup(for: 123), .arrow)
        XCTAssertEqual(KeyCodeClassifier.resolveKeyGroup(for: 126), .arrow)
    }

    func testUnknownKeyCodeFallsBackToAlphaGroup() {
        XCTAssertEqual(KeyCodeClassifier.resolveKeyGroup(for: 0), .alpha)
        XCTAssertEqual(KeyCodeClassifier.resolveKeyGroup(for: 999), .alpha)
    }
}
#endif
