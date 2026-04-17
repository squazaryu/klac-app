#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class KlacVersioningTests: XCTestCase {
    func testNormalizedVersionDropsVPrefixAndWhitespace() {
        XCTAssertEqual(KlacVersioning.normalizedVersion(fromTag: "  v2.1.1  "), "2.1.1")
        XCTAssertEqual(KlacVersioning.normalizedVersion(fromTag: "V2.0.5"), "2.0.5")
    }

    func testParseVersionExtractsCoreSuffixAndEmbeddedBuild() {
        let parsed = KlacVersioning.parseVersion("2.0.5-b16-dev")
        XCTAssertEqual(parsed.core, [2, 0, 5])
        XCTAssertEqual(parsed.suffix, "b16-dev")
        XCTAssertEqual(parsed.embeddedBuild, 16)
    }

    func testIsVersionComparesCoreNumbersFirst() {
        XCTAssertTrue(KlacVersioning.isVersion("2.0.6", newerThan: "2.0.5", currentBuild: 1))
        XCTAssertFalse(KlacVersioning.isVersion("2.0.4", newerThan: "2.0.5", currentBuild: 99))
    }

    func testIsVersionUsesEmbeddedBuildWhenCoreIsEqual() {
        XCTAssertTrue(KlacVersioning.isVersion("2.0.5-b17", newerThan: "2.0.5-b16", currentBuild: 16))
        XCTAssertFalse(KlacVersioning.isVersion("2.0.5-b16", newerThan: "2.0.5-b16", currentBuild: 16))
    }
}
#endif
