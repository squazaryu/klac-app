#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class DiagnosticsTimestampProviderTests: XCTestCase {
    func testDebugTimestampContainsISOSeparatorAndMillis() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let timestamp = DiagnosticsTimestampProvider.debugTimestamp(date: date)

        XCTAssertTrue(timestamp.contains("T"))
        XCTAssertTrue(timestamp.contains("."))
        XCTAssertTrue(timestamp.hasSuffix("Z"))
    }

    func testFileTimestampMatchesExpectedFormat() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let timestamp = DiagnosticsTimestampProvider.fileTimestamp(date: date)

        let regex = try! NSRegularExpression(pattern: #"^\d{8}-\d{6}$"#)
        let range = NSRange(location: 0, length: timestamp.utf16.count)
        XCTAssertNotNil(regex.firstMatch(in: timestamp, options: [], range: range))
    }
}
#endif
