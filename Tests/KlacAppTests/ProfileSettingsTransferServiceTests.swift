#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class ProfileSettingsTransferServiceTests: XCTestCase {
    private let service = ProfileSettingsTransferService()

    func testExportAndImportRoundTrip() throws {
        let state = ProfileSettingsState(
            selectedProfile: .mechvibesEGCrystalPurple,
            volume: 0.72,
            variation: 0.31,
            playKeyUp: true,
            pressLevel: 1.05,
            releaseLevel: 0.66,
            spaceLevel: 1.2
        )

        let data = try service.exportData(from: state)
        let imported = try service.importState(from: data, fallbackProfile: .kalihBoxWhite)

        XCTAssertEqual(imported, state)
    }

    func testImportClampsValuesToExpectedRanges() throws {
        let json = """
        {
          "profile": "kalihBoxWhite",
          "volume": 10.0,
          "variation": -1.0,
          "playKeyUp": false,
          "pressLevel": 8.0,
          "releaseLevel": -2.0,
          "spaceLevel": 100.0
        }
        """
        let imported = try service.importState(
            from: Data(json.utf8),
            fallbackProfile: .customPack
        )

        XCTAssertEqual(imported.selectedProfile, .kalihBoxWhite)
        XCTAssertEqual(imported.volume, 1.0, accuracy: 0.0001)
        XCTAssertEqual(imported.variation, 0.0, accuracy: 0.0001)
        XCTAssertEqual(imported.pressLevel, 1.6, accuracy: 0.0001)
        XCTAssertEqual(imported.releaseLevel, 0.1, accuracy: 0.0001)
        XCTAssertEqual(imported.spaceLevel, 1.8, accuracy: 0.0001)
    }

    func testImportUsesFallbackProfileForUnknownProfileRawValue() throws {
        let json = """
        {
          "profile": "unknown-profile",
          "volume": 0.4,
          "variation": 0.2,
          "playKeyUp": true,
          "pressLevel": 1.0,
          "releaseLevel": 0.6,
          "spaceLevel": 1.1
        }
        """

        let imported = try service.importState(
            from: Data(json.utf8),
            fallbackProfile: .mechvibesEGOreo
        )

        XCTAssertEqual(imported.selectedProfile, .mechvibesEGOreo)
    }
}
#endif
