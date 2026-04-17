#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class SamplePackParsersTests: XCTestCase {
    func testDecodeMechvibesConfigSupportsStringSpriteAndNil() throws {
        let json = """
        {
          "sound": "wav",
          "key_define_type": "single",
          "defines": {
            "key-down-1": "down.wav",
            "key-up-1": [0, 100, 0.9],
            "space-1": null
          }
        }
        """
        let data = Data(json.utf8)
        let config = try SamplePackParsers.decodeMechvibesConfig(from: data)

        XCTAssertEqual(config.sound, "wav")
        XCTAssertEqual(config.key_define_type, "single")
        XCTAssertEqual(config.defines.count, 3)
    }

    func testDecodeManifestPackReadsGroupsAndRelease() throws {
        let json = """
        {
          "groups": {
            "key-down": {
              "soft": ["a.wav"],
              "medium": ["b.wav"],
              "hard": ["c.wav"],
              "slam": ["d.wav"]
            }
          },
          "release": {
            "generic": ["up1.wav", "up2.wav"]
          }
        }
        """
        let data = Data(json.utf8)
        let manifest = try SamplePackParsers.decodeManifestPack(from: data)

        XCTAssertEqual(manifest.groups["key-down"]?.soft?.first, "a.wav")
        XCTAssertEqual(manifest.groups["key-down"]?.slam?.first, "d.wav")
        XCTAssertEqual(manifest.release?["generic"]?.count, 2)
    }
}
#endif
