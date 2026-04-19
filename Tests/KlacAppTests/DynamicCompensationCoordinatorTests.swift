#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class DynamicCompensationCoordinatorTests: XCTestCase {
    func testSimpleStrictModeUsesInverseGain() {
        let input = baseInput(
            strictVolumeNormalizationEnabled: true,
            levelTuningMode: .simple,
            lastSystemVolume: 1.0,
            autoNormalizeTargetAt100: 0.4
        )

        let gain = DynamicCompensationCoordinator.resolveGain(input)

        XCTAssertEqual(gain, 0.4, accuracy: 0.0001)
    }

    func testDynamicCompensationBoostsAtLowSystemVolume() {
        let input = baseInput(
            strictVolumeNormalizationEnabled: false,
            dynamicCompensationEnabled: true,
            lastSystemVolume: 0.2,
            compensationStrength: 1.0
        )

        let gain = DynamicCompensationCoordinator.resolveGain(input)
        XCTAssertGreaterThan(gain, 1.0)
    }

    func testOutputDeviceBoostScalesGain() {
        let inputA = baseInput(currentOutputDeviceBoost: 1.0)
        let inputB = baseInput(currentOutputDeviceBoost: 1.5)

        let gainA = DynamicCompensationCoordinator.resolveGain(inputA)
        let gainB = DynamicCompensationCoordinator.resolveGain(inputB)

        XCTAssertEqual(gainB, gainA * 1.5, accuracy: 0.0001)
    }

    private func baseInput(
        strictVolumeNormalizationEnabled: Bool = false,
        levelTuningMode: KlacLevelTuningMode = .curve,
        lastSystemVolume: Double = 0.6,
        autoNormalizeTargetAt100: Double = 0.45,
        dynamicCompensationEnabled: Bool = false,
        compensationStrength: Double = 1.0,
        currentOutputDeviceBoost: Double = 1.0
    ) -> DynamicCompensationInput {
        DynamicCompensationInput(
            strictVolumeNormalizationEnabled: strictVolumeNormalizationEnabled,
            levelTuningMode: levelTuningMode,
            lastSystemVolume: lastSystemVolume,
            autoNormalizeTargetAt100: autoNormalizeTargetAt100,
            levelMacLow: 0.30,
            levelKbdLow: 1.60,
            levelMacLowMid: 0.45,
            levelKbdLowMid: 1.30,
            levelMacMid: 0.60,
            levelKbdMid: 1.00,
            levelMacHighMid: 0.80,
            levelKbdHighMid: 0.70,
            levelMacHigh: 1.00,
            levelKbdHigh: 0.45,
            dynamicCompensationEnabled: dynamicCompensationEnabled,
            compensationStrength: compensationStrength,
            currentOutputDeviceBoost: currentOutputDeviceBoost
        )
    }
}
#endif
