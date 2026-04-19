#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class SoundStatePatchMapperTests: XCTestCase {
    func testImportedProfilePatchMapsOnlyProfileFields() {
        let state = ProfileSettingsState(
            selectedProfile: .mechvibesBoxJade,
            volume: 0.44,
            variation: 0.23,
            playKeyUp: false,
            pressLevel: 1.11,
            releaseLevel: 0.72,
            spaceLevel: 1.32
        )

        let patch = SoundStatePatchMapper.importedProfilePatch(from: state)

        XCTAssertEqual(patch.selectedProfile, .mechvibesBoxJade)
        XCTAssertEqual(patch.volume, 0.44, accuracy: 0.0001)
        XCTAssertEqual(patch.variation, 0.23, accuracy: 0.0001)
        XCTAssertEqual(patch.playKeyUp, false)
        XCTAssertEqual(patch.pressLevel, 1.11, accuracy: 0.0001)
        XCTAssertEqual(patch.releaseLevel, 0.72, accuracy: 0.0001)
        XCTAssertEqual(patch.spaceLevel, 1.32, accuracy: 0.0001)
        XCTAssertNil(patch.pitchVariation)
        XCTAssertNil(patch.levelMacLowMid)
        XCTAssertNil(patch.currentOutputDeviceBoost)
    }

    func testDeviceSnapshotPatchMapsRuntimeFields() {
        let snapshot = DeviceSoundStateDTO(
            volume: 0.61,
            variation: 0.21,
            pitchVariation: 0.37,
            pressLevel: 1.2,
            releaseLevel: 0.8,
            spaceLevel: 1.15,
            levelMacLowMid: 0.31,
            levelKbdLowMid: 1.43,
            levelMacHighMid: 0.81,
            levelKbdHighMid: 0.72,
            stackModeEnabled: true,
            limiterEnabled: true,
            limiterDrive: 1.34,
            minInterKeyGapMs: 9,
            releaseDuckingStrength: 0.68,
            releaseDuckingWindowMs: 97,
            releaseTailTightness: 0.4,
            currentOutputDeviceBoost: 1.6
        )

        let patch = SoundStatePatchMapper.deviceSnapshotPatch(from: snapshot)

        XCTAssertNil(patch.selectedProfile)
        XCTAssertEqual(patch.volume, 0.61, accuracy: 0.0001)
        XCTAssertEqual(patch.variation, 0.21, accuracy: 0.0001)
        XCTAssertEqual(patch.pitchVariation, 0.37, accuracy: 0.0001)
        XCTAssertEqual(patch.pressLevel, 1.2, accuracy: 0.0001)
        XCTAssertEqual(patch.releaseLevel, 0.8, accuracy: 0.0001)
        XCTAssertEqual(patch.spaceLevel, 1.15, accuracy: 0.0001)
        XCTAssertEqual(patch.levelMacLowMid, 0.31, accuracy: 0.0001)
        XCTAssertEqual(patch.levelKbdLowMid, 1.43, accuracy: 0.0001)
        XCTAssertEqual(patch.levelMacHighMid, 0.81, accuracy: 0.0001)
        XCTAssertEqual(patch.levelKbdHighMid, 0.72, accuracy: 0.0001)
        XCTAssertEqual(patch.stackModeEnabled, true)
        XCTAssertEqual(patch.limiterEnabled, true)
        XCTAssertEqual(patch.limiterDrive, 1.34, accuracy: 0.0001)
        XCTAssertEqual(patch.minInterKeyGapMs, 9, accuracy: 0.0001)
        XCTAssertEqual(patch.releaseDuckingStrength, 0.68, accuracy: 0.0001)
        XCTAssertEqual(patch.releaseDuckingWindowMs, 97, accuracy: 0.0001)
        XCTAssertEqual(patch.releaseTailTightness, 0.4, accuracy: 0.0001)
        XCTAssertEqual(patch.currentOutputDeviceBoost, 1.6, accuracy: 0.0001)
        XCTAssertNil(patch.playKeyUp)
    }
}
#endif
