import Foundation

struct DynamicCompensationInput {
    let strictVolumeNormalizationEnabled: Bool
    let levelTuningMode: KlacLevelTuningMode
    let lastSystemVolume: Double
    let autoNormalizeTargetAt100: Double
    let levelMacLow: Double
    let levelKbdLow: Double
    let levelMacLowMid: Double
    let levelKbdLowMid: Double
    let levelMacMid: Double
    let levelKbdMid: Double
    let levelMacHighMid: Double
    let levelKbdHighMid: Double
    let levelMacHigh: Double
    let levelKbdHigh: Double
    let dynamicCompensationEnabled: Bool
    let compensationStrength: Double
    let currentOutputDeviceBoost: Double
}

enum DynamicCompensationCoordinator {
    static func resolveGain(_ input: DynamicCompensationInput) -> Double {
        var gain: Double
        if input.strictVolumeNormalizationEnabled {
            if input.levelTuningMode == .simple {
                gain = AudioCompensationMath.autoInverseGain(
                    systemVolumeScalar: input.lastSystemVolume,
                    targetAt100: input.autoNormalizeTargetAt100
                )
            } else {
                gain = CompensationCurveCoordinator.strictCurveGain(
                    systemVolume: input.lastSystemVolume,
                    targetAt100: input.autoNormalizeTargetAt100,
                    macLow: input.levelMacLow,
                    kbdLow: input.levelKbdLow,
                    macLowMid: input.levelMacLowMid,
                    kbdLowMid: input.levelKbdLowMid,
                    macMid: input.levelMacMid,
                    kbdMid: input.levelKbdMid,
                    macHighMid: input.levelMacHighMid,
                    kbdHighMid: input.levelKbdHighMid,
                    macHigh: input.levelMacHigh,
                    kbdHigh: input.levelKbdHigh
                )
            }
        } else {
            gain = CompensationCurveCoordinator.curveGain(
                systemVolume: input.lastSystemVolume,
                macLow: input.levelMacLow,
                kbdLow: input.levelKbdLow,
                macLowMid: input.levelMacLowMid,
                kbdLowMid: input.levelKbdLowMid,
                macMid: input.levelMacMid,
                kbdMid: input.levelKbdMid,
                macHighMid: input.levelMacHighMid,
                kbdHighMid: input.levelKbdHighMid,
                macHigh: input.levelMacHigh,
                kbdHigh: input.levelKbdHigh
            )
        }

        gain *= input.currentOutputDeviceBoost

        if input.dynamicCompensationEnabled && !input.strictVolumeNormalizationEnabled {
            let lowVolumeFactor = max(0.0, 1.0 - input.lastSystemVolume)
            gain *= 1.0 + lowVolumeFactor * (0.18 + input.compensationStrength * 0.95)
        }

        return gain
    }
}

