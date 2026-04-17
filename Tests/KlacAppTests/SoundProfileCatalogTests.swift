#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class SoundProfileCatalogTests: XCTestCase {
    func testKalihProfileUsesManifestOnlySource() {
        let source = SoundProfileSource.resolve(for: .kalihBoxWhite)
        switch source.kind {
        case let .manifestOnly(resourceDirectory, configFilename):
            XCTAssertEqual(resourceDirectory, "Sounds/kalihboxwhite")
            XCTAssertEqual(configFilename, "pack-kalihboxwhite.json")
        default:
            XCTFail("Expected .manifestOnly source")
        }
    }

    func testOperaGXUsesManifestOrFallbackMechvibesConfig() {
        let source = SoundProfileSource.resolve(for: .mechvibesOperaGX)
        switch source.kind {
        case let .manifestOrMechvibes(resourceDirectory, manifestFilename, mechvibesConfigFilename):
            XCTAssertEqual(resourceDirectory, "Sounds/mv-opera-gx")
            XCTAssertEqual(manifestFilename, "pack-opera-gx.json")
            XCTAssertEqual(mechvibesConfigFilename, "config-opera-gx.json")
        default:
            XCTFail("Expected .manifestOrMechvibes source")
        }
    }
}
#endif
