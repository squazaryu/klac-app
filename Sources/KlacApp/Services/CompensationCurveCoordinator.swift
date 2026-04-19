import Foundation

enum CompensationCurveCoordinator {
    static func curveGain(
        systemVolume: Double,
        macLow: Double,
        kbdLow: Double,
        macLowMid: Double,
        kbdLowMid: Double,
        macMid: Double,
        kbdMid: Double,
        macHighMid: Double,
        kbdHighMid: Double,
        macHigh: Double,
        kbdHigh: Double
    ) -> Double {
        let points = [
            GainCurvePoint(x: macLow.clamped(to: 0.05 ... 0.90), y: kbdLow.clamped(to: 0.20 ... 4.00)),
            GainCurvePoint(x: macLowMid.clamped(to: 0.08 ... 0.93), y: kbdLowMid.clamped(to: 0.20 ... 4.00)),
            GainCurvePoint(x: macMid.clamped(to: 0.05 ... 0.95), y: kbdMid.clamped(to: 0.20 ... 4.00)),
            GainCurvePoint(x: macHighMid.clamped(to: 0.10 ... 0.98), y: kbdHighMid.clamped(to: 0.20 ... 4.00)),
            GainCurvePoint(x: macHigh.clamped(to: 0.10 ... 1.00), y: kbdHigh.clamped(to: 0.20 ... 4.00)),
        ]
        return AudioCompensationMath.curveGain(systemVolume: systemVolume, points: points)
    }

    static func strictCurveGain(
        systemVolume: Double,
        targetAt100: Double,
        macLow: Double,
        kbdLow: Double,
        macLowMid: Double,
        kbdLowMid: Double,
        macMid: Double,
        kbdMid: Double,
        macHighMid: Double,
        kbdHighMid: Double,
        macHigh: Double,
        kbdHigh: Double
    ) -> Double {
        let base = curveGain(
            systemVolume: systemVolume,
            macLow: macLow,
            kbdLow: kbdLow,
            macLowMid: macLowMid,
            kbdLowMid: kbdLowMid,
            macMid: macMid,
            kbdMid: kbdMid,
            macHighMid: macHighMid,
            kbdHighMid: kbdHighMid,
            macHigh: macHigh,
            kbdHigh: kbdHigh
        )
        let at100 = max(
            0.001,
            curveGain(
                systemVolume: 1.0,
                macLow: macLow,
                kbdLow: kbdLow,
                macLowMid: macLowMid,
                kbdLowMid: kbdLowMid,
                macMid: macMid,
                kbdMid: kbdMid,
                macHighMid: macHighMid,
                kbdHighMid: kbdHighMid,
                macHigh: macHigh,
                kbdHigh: kbdHigh
            )
        )
        let scale = targetAt100.clamped(to: 0.20 ... 1.20) / at100
        return (base * scale).clamped(to: 0.20 ... 12.0)
    }
}

