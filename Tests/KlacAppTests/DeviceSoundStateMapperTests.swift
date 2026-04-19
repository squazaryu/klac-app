#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class DeviceSoundStateMapperTests: XCTestCase {
    func testToDTOMapsAllFields() {
        let source = DeviceSoundStateSource(
            volume: 0.7,
            variation: 0.2,
            pitchVariation: 0.33,
            pressLevel: 1.1,
            releaseLevel: 0.8,
            spaceLevel: 1.25,
            levelMacLowMid: 0.44,
            levelKbdLowMid: 1.2,
            levelMacHighMid: 0.77,
            levelKbdHighMid: 0.65,
            stackModeEnabled: true,
            limiterEnabled: false,
            limiterDrive: 1.4,
            minInterKeyGapMs: 12,
            releaseDuckingStrength: 0.6,
            releaseDuckingWindowMs: 95,
            releaseTailTightness: 0.42,
            currentOutputDeviceBoost: 1.8
        )

        let dto = DeviceSoundStateMapper.toDTO(source)

        XCTAssertEqual(dto.volume, 0.7, accuracy: 0.0001)
        XCTAssertEqual(dto.variation, 0.2, accuracy: 0.0001)
        XCTAssertEqual(dto.pitchVariation, 0.33, accuracy: 0.0001)
        XCTAssertEqual(dto.pressLevel, 1.1, accuracy: 0.0001)
        XCTAssertEqual(dto.releaseLevel, 0.8, accuracy: 0.0001)
        XCTAssertEqual(dto.spaceLevel, 1.25, accuracy: 0.0001)
        XCTAssertEqual(dto.levelMacLowMid, 0.44, accuracy: 0.0001)
        XCTAssertEqual(dto.levelKbdLowMid, 1.2, accuracy: 0.0001)
        XCTAssertEqual(dto.levelMacHighMid, 0.77, accuracy: 0.0001)
        XCTAssertEqual(dto.levelKbdHighMid, 0.65, accuracy: 0.0001)
        XCTAssertEqual(dto.stackModeEnabled, true)
        XCTAssertEqual(dto.limiterEnabled, false)
        XCTAssertEqual(dto.limiterDrive, 1.4, accuracy: 0.0001)
        XCTAssertEqual(dto.minInterKeyGapMs, 12, accuracy: 0.0001)
        XCTAssertEqual(dto.releaseDuckingStrength, 0.6, accuracy: 0.0001)
        XCTAssertEqual(dto.releaseDuckingWindowMs, 95, accuracy: 0.0001)
        XCTAssertEqual(dto.releaseTailTightness, 0.42, accuracy: 0.0001)
        XCTAssertEqual(dto.currentOutputDeviceBoost, 1.8, accuracy: 0.0001)
    }
}
#endif
