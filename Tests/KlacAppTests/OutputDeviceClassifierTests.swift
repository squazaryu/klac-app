#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class OutputDeviceClassifierTests: XCTestCase {
    func testLooksLikeHeadphonesRecognizesCommonHeadsetNames() {
        XCTAssertTrue(OutputDeviceClassifier.looksLikeHeadphones("Nothing Headphone (1)"))
        XCTAssertTrue(OutputDeviceClassifier.looksLikeHeadphones("Sony WH-1000XM5"))
        XCTAssertTrue(OutputDeviceClassifier.looksLikeHeadphones("AirPods Pro"))
    }

    func testLooksLikeHeadphonesRejectsSpeakers() {
        XCTAssertFalse(OutputDeviceClassifier.looksLikeHeadphones("MacBook Pro Speakers"))
        XCTAssertFalse(OutputDeviceClassifier.looksLikeHeadphones("Built-in Speaker"))
    }
}
#endif
