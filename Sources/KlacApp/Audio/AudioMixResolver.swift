import Foundation

struct DownMixInput {
    let keyGroup: KeyGroup
    let autorepeat: Bool
    let masterVolume: Float
    let pressLevel: Float
    let spaceLevel: Float
    let dynamicCompensationGain: Float
    let typingSpeedGain: Float
    let variation: Float
    let strictLevelingEnabled: Bool
    let stackModeEnabled: Bool
    let stackDensity: Float
    let minInterKeyGapMs: Float
    let lastDownHitTime: CFAbsoluteTime
    let now: CFAbsoluteTime
    let slamThreshold: CFAbsoluteTime
    let hardThreshold: CFAbsoluteTime
    let mediumThreshold: CFAbsoluteTime
    let jitterRandom: Float
    let interruptRandom: Float
}

struct DownMixResult {
    let gain: Float
    let interrupt: Bool
    let layer: VelocityLayer
    let nextLastDownHitTime: CFAbsoluteTime
    let interKeyGap: CFAbsoluteTime
}

struct UpMixInput {
    let masterVolume: Float
    let releaseLevel: Float
    let dynamicCompensationGain: Float
    let typingSpeedGain: Float
    let variation: Float
    let strictLevelingEnabled: Bool
    let stackModeEnabled: Bool
    let stackDensity: Float
    let releaseDuckingStrength: Float
    let releaseDuckingWindowMs: Float
    let releaseTailTightness: Float
    let now: CFAbsoluteTime
    let lastDownHitTime: CFAbsoluteTime
    let jitterRandom: Float
    let releaseKeepRandom: Float
    let releaseInterruptRandom: Float
}

enum UpMixResult {
    case skip
    case play(gain: Float, interrupt: Bool)
}

enum AudioMixResolver {
    static func keyLevel(for keyGroup: KeyGroup, pressLevel: Float, spaceLevel: Float) -> Float {
        switch keyGroup {
        case .space:
            return spaceLevel
        case .enter:
            return (pressLevel + spaceLevel) * 0.5
        case .delete:
            return pressLevel * 0.95
        default:
            return pressLevel
        }
    }

    static func resolveVelocityLayer(
        interKeyGap: CFAbsoluteTime,
        stackDensity: Float,
        slamThreshold: CFAbsoluteTime,
        hardThreshold: CFAbsoluteTime,
        mediumThreshold: CFAbsoluteTime
    ) -> VelocityLayer {
        let dt = max(0.0, interKeyGap)
        let densityBias = Double(stackDensity.clamped(to: 0.0 ... 1.0)) * 0.018
        let adjusted = max(0.0, dt - densityBias)
        switch adjusted {
        case ..<slamThreshold:
            return .slam
        case ..<hardThreshold:
            return .hard
        case ..<mediumThreshold:
            return .medium
        default:
            return .soft
        }
    }

    static func resolveDownMix(_ input: DownMixInput) -> DownMixResult {
        let keyLevel = keyLevel(for: input.keyGroup, pressLevel: input.pressLevel, spaceLevel: input.spaceLevel)
        let effectiveVariation = max(0.10, input.variation)
        let jitterScale: Float = input.strictLevelingEnabled ? 0.04 : 0.34
        var gainJitter = input.jitterRandom.clamped(to: -effectiveVariation ... effectiveVariation) * jitterScale
        if input.autorepeat { gainJitter -= 0.1 }

        var gain = (
            input.masterVolume * keyLevel * input.dynamicCompensationGain * input.typingSpeedGain + gainJitter
        ).clamped(to: 0.03 ... 16.0)
        var interrupt = false

        let dt = input.lastDownHitTime == 0 ? 0.18 : input.now - input.lastDownHitTime
        let minGapSeconds = Double(input.minInterKeyGapMs.clamped(to: 0 ... 45)) / 1000.0
        let isVeryFastChain = dt < minGapSeconds
        let layer = resolveVelocityLayer(
            interKeyGap: dt,
            stackDensity: input.stackModeEnabled ? input.stackDensity : 0,
            slamThreshold: input.slamThreshold,
            hardThreshold: input.hardThreshold,
            mediumThreshold: input.mediumThreshold
        )

        if input.stackModeEnabled && !input.strictLevelingEnabled {
            let density = input.stackDensity.clamped(to: 0.0 ... 1.0)
            let proximity = Float(max(0.0, 1.0 - dt / 0.14))
            let stackBoost = 1.0 + (density * density) * proximity * 1.35
            gain = (gain * stackBoost).clamped(to: 0.03 ... 8.0)
            gain = softKneeCompress(gain, kneeStart: 1.6, max: 2.4)
            let interruptChance = ((density - 0.40) / 0.60).clamped(to: 0.0 ... 1.0) * proximity
            interrupt = input.interruptRandom.clamped(to: 0 ... 1) < interruptChance
        }

        if isVeryFastChain {
            let fastRatio = Float((minGapSeconds - dt) / max(0.001, minGapSeconds)).clamped(to: 0 ... 1)
            let attenuation = 1.0 - fastRatio * 0.28
            gain = (gain * attenuation).clamped(to: 0.03 ... 8.0)
            interrupt = true
        }

        return DownMixResult(
            gain: gain,
            interrupt: interrupt,
            layer: layer,
            nextLastDownHitTime: input.now,
            interKeyGap: dt
        )
    }

    static func resolveUpMix(_ input: UpMixInput) -> UpMixResult {
        if input.stackModeEnabled && !input.strictLevelingEnabled {
            let density = input.stackDensity.clamped(to: 0.0 ... 1.0)
            if density >= 0.65 {
                return .skip
            }
            let keepProbability = (1.0 - density).clamped(to: 0.02 ... 1.0)
            if input.releaseKeepRandom.clamped(to: 0 ... 1) > keepProbability {
                return .skip
            }
        }

        let effectiveVariation = max(0.10, input.variation)
        let releaseJitterScale: Float = input.strictLevelingEnabled ? 0.02 : 0.16
        var gain = (
            input.masterVolume * input.releaseLevel * input.dynamicCompensationGain * input.typingSpeedGain +
                input.jitterRandom.clamped(to: -effectiveVariation ... effectiveVariation) * releaseJitterScale
        ).clamped(to: 0.02 ... 8.0)

        let dtFromLastDown = input.now - input.lastDownHitTime
        let duckWindowSeconds = Double(input.releaseDuckingWindowMs.clamped(to: 20 ... 180)) / 1000.0
        if duckWindowSeconds > 0 {
            let proximity = Float(max(0, 1.0 - dtFromLastDown / duckWindowSeconds)).clamped(to: 0 ... 1)
            let duckStrength = input.releaseDuckingStrength.clamped(to: 0 ... 1)
            let ducked = 1.0 - proximity * duckStrength
            gain = (gain * ducked).clamped(to: 0.005 ... 8.0)
        }

        if input.stackModeEnabled && !input.strictLevelingEnabled {
            let tailCut = (1.0 - input.stackDensity * 0.78).clamped(to: 0.15 ... 1.0)
            gain = (gain * tailCut).clamped(to: 0.01 ... 1.1)
            gain = softKneeCompress(gain, kneeStart: 0.55, max: 0.85)
        }

        let tailTightness = input.releaseTailTightness.clamped(to: 0 ... 1)
        if tailTightness > 0 {
            let tailScale = (1.0 - tailTightness * 0.42).clamped(to: 0.25 ... 1.0)
            gain = (gain * tailScale).clamped(to: 0.005 ... 8.0)
        }

        let releaseInterruptChance = ((input.stackDensity - 0.55) / 0.45).clamped(to: 0.0 ... 1.0) * 0.7
        let nearDownForInterrupt = dtFromLastDown < (duckWindowSeconds * 0.34)
        let interrupt = (
            !input.strictLevelingEnabled &&
                input.stackModeEnabled &&
                input.releaseInterruptRandom.clamped(to: 0 ... 1) < releaseInterruptChance
        ) || nearDownForInterrupt

        return .play(gain: gain, interrupt: interrupt)
    }

    static func softKneeCompress(_ value: Float, kneeStart: Float, max: Float) -> Float {
        guard value > kneeStart else { return value }
        let overflow = value - kneeStart
        let compressed = kneeStart + overflow * 0.35
        return min(compressed, max)
    }
}
