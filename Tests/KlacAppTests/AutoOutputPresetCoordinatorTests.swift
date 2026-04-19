#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class AutoOutputPresetCoordinatorTests: XCTestCase {
    func testDisabledModeSkipsApply() {
        let decision = AutoOutputPresetCoordinator.decide(
            autoOutputPresetEnabled: false,
            deviceUID: "dev-1",
            lastAutoPresetDeviceUID: "",
            deviceName: "MacBook Pro Speakers"
        )

        XCTAssertFalse(decision.shouldApply)
        XCTAssertNil(decision.nextLastAutoPresetDeviceUID)
        XCTAssertNil(decision.presetKind)
    }

    func testEmptyDeviceUIDSkipsApply() {
        let decision = AutoOutputPresetCoordinator.decide(
            autoOutputPresetEnabled: true,
            deviceUID: "",
            lastAutoPresetDeviceUID: "",
            deviceName: "Nothing Headphone (1)"
        )

        XCTAssertFalse(decision.shouldApply)
        XCTAssertNil(decision.nextLastAutoPresetDeviceUID)
        XCTAssertNil(decision.presetKind)
    }

    func testSameDeviceUIDSkipsRepeatedApply() {
        let decision = AutoOutputPresetCoordinator.decide(
            autoOutputPresetEnabled: true,
            deviceUID: "dev-1",
            lastAutoPresetDeviceUID: "dev-1",
            deviceName: "Nothing Headphone (1)"
        )

        XCTAssertFalse(decision.shouldApply)
        XCTAssertNil(decision.nextLastAutoPresetDeviceUID)
        XCTAssertNil(decision.presetKind)
    }

    func testHeadphonesDeviceSelectsHeadphonesPreset() {
        let decision = AutoOutputPresetCoordinator.decide(
            autoOutputPresetEnabled: true,
            deviceUID: "dev-bt",
            lastAutoPresetDeviceUID: "old",
            deviceName: "Nothing Headphone (1)"
        )

        XCTAssertTrue(decision.shouldApply)
        XCTAssertEqual(decision.nextLastAutoPresetDeviceUID, "dev-bt")
        XCTAssertEqual(decision.presetKind, .headphones)
    }

    func testSpeakersDeviceSelectsSpeakersPreset() {
        let decision = AutoOutputPresetCoordinator.decide(
            autoOutputPresetEnabled: true,
            deviceUID: "dev-speakers",
            lastAutoPresetDeviceUID: "old",
            deviceName: "MacBook Pro Speakers"
        )

        XCTAssertTrue(decision.shouldApply)
        XCTAssertEqual(decision.nextLastAutoPresetDeviceUID, "dev-speakers")
        XCTAssertEqual(decision.presetKind, .speakers)
    }
}
#endif
