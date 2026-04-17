#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class SoundPresetServiceTests: XCTestCase {
    func testHeadphonesPresetHasExpectedCoreValues() {
        let preset = SoundPresetService.headphonesPreset()
        XCTAssertEqual(preset.volume, 0.62, accuracy: 0.0001)
        XCTAssertEqual(preset.releaseDuckingWindowMs, 105, accuracy: 0.0001)
        XCTAssertTrue(preset.limiterEnabled)
    }

    func testSpeakersPresetHasExpectedCoreValues() {
        let preset = SoundPresetService.speakersPreset()
        XCTAssertEqual(preset.volume, 0.46, accuracy: 0.0001)
        XCTAssertEqual(preset.minInterKeyGapMs, 10, accuracy: 0.0001)
        XCTAssertEqual(preset.releaseTailTightness, 0.40, accuracy: 0.0001)
    }

    func testProfilePresetReturnsNilForNonCustomizedProfile() {
        XCTAssertNil(SoundPresetService.profilePreset(for: .kalihBoxWhite))
    }

    func testProfilePresetReturnsLabelForCrystalPurple() {
        let preset = SoundPresetService.profilePreset(for: .mechvibesEGCrystalPurple)
        XCTAssertEqual(preset?.label, "Crystal Purple: живой и звонкий")
        XCTAssertEqual(preset?.settings.variation, 0.38, accuracy: 0.0001)
    }
}
#endif
