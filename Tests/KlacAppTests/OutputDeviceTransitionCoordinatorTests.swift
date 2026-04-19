#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class OutputDeviceTransitionCoordinatorTests: XCTestCase {
    func testBeginPlanSavesPreviousAndAttemptsRestoreWhenPerDeviceEnabled() {
        let context = OutputDeviceTransitionContext(
            perDeviceSoundProfileEnabled: true,
            previousDeviceUID: "old",
            newDeviceUID: "new",
            isInitialProbe: false,
            hasPersistedPrimarySettings: true
        )

        let plan = OutputDeviceTransitionCoordinator.beginPlan(for: context)

        XCTAssertTrue(plan.shouldSavePreviousSnapshot)
        XCTAssertTrue(plan.shouldAttemptRestoreSnapshot)
    }

    func testBeginPlanSkipsSaveAndRestoreWhenPerDeviceDisabled() {
        let context = OutputDeviceTransitionContext(
            perDeviceSoundProfileEnabled: false,
            previousDeviceUID: "old",
            newDeviceUID: "new",
            isInitialProbe: false,
            hasPersistedPrimarySettings: true
        )

        let plan = OutputDeviceTransitionCoordinator.beginPlan(for: context)

        XCTAssertFalse(plan.shouldSavePreviousSnapshot)
        XCTAssertFalse(plan.shouldAttemptRestoreSnapshot)
    }

    func testFinalizePlanMarksDeviceProfileWhenRestored() {
        let context = OutputDeviceTransitionContext(
            perDeviceSoundProfileEnabled: true,
            previousDeviceUID: "old",
            newDeviceUID: "new",
            isInitialProbe: false,
            hasPersistedPrimarySettings: true
        )

        let plan = OutputDeviceTransitionCoordinator.finalizePlan(for: context, restoredSnapshot: true)

        XCTAssertEqual(plan.presetAction, .markDeviceProfile)
        XCTAssertFalse(plan.shouldSaveNewSnapshot)
        XCTAssertEqual(plan.statusLabel, "Профиль устройства")
    }

    func testFinalizePlanAppliesAutoPresetWhenAllowed() {
        let context = OutputDeviceTransitionContext(
            perDeviceSoundProfileEnabled: true,
            previousDeviceUID: "old",
            newDeviceUID: "new",
            isInitialProbe: false,
            hasPersistedPrimarySettings: true
        )

        let plan = OutputDeviceTransitionCoordinator.finalizePlan(for: context, restoredSnapshot: false)

        XCTAssertEqual(plan.presetAction, .applyAutoPreset)
        XCTAssertTrue(plan.shouldSaveNewSnapshot)
        XCTAssertNil(plan.statusLabel)
    }

    func testFinalizePlanMarksSavedSettingsOnInitialProbeWithPersistedSettings() {
        let context = OutputDeviceTransitionContext(
            perDeviceSoundProfileEnabled: true,
            previousDeviceUID: "",
            newDeviceUID: "new",
            isInitialProbe: true,
            hasPersistedPrimarySettings: true
        )

        let plan = OutputDeviceTransitionCoordinator.finalizePlan(for: context, restoredSnapshot: false)

        XCTAssertEqual(plan.presetAction, .markSavedSettings)
        XCTAssertTrue(plan.shouldSaveNewSnapshot)
        XCTAssertEqual(plan.statusLabel, "Сохраненные настройки")
    }
}
#endif
