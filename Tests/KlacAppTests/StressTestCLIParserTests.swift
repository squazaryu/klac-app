#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class StressTestCLIParserTests: XCTestCase {
    func testReturnsNilWhenFlagMissing() {
        XCTAssertNil(StressTestCLIParser.parseDuration(arguments: ["KlacApp"]))
    }

    func testParsesSeparatedFlagValue() {
        let value = StressTestCLIParser.parseDuration(arguments: ["KlacApp", "--stress-test", "45"])
        XCTAssertEqual(value, 45, accuracy: 0.0001)
    }

    func testUsesDefaultWhenSeparatedFlagValueMissing() {
        let value = StressTestCLIParser.parseDuration(arguments: ["KlacApp", "--stress-test"])
        XCTAssertEqual(value, 20, accuracy: 0.0001)
    }

    func testParsesInlineFlagValue() {
        let value = StressTestCLIParser.parseDuration(arguments: ["KlacApp", "--stress-test=30"])
        XCTAssertEqual(value, 30, accuracy: 0.0001)
    }

    func testUsesDefaultWhenInlineFlagValueInvalid() {
        let value = StressTestCLIParser.parseDuration(arguments: ["KlacApp", "--stress-test=abc"])
        XCTAssertEqual(value, 20, accuracy: 0.0001)
    }
}
#endif
