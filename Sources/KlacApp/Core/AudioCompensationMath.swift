import Foundation

struct GainCurvePoint {
    let x: Double
    let y: Double
}

enum AudioCompensationMath {
    static func autoInverseGain(systemVolumeScalar: Double, targetAt100: Double) -> Double {
        let scalar = systemVolumeScalar.clamped(to: 0.05 ... 1.0)
        let effective = pow(scalar, 2.2).clamped(to: 0.003 ... 1.0)
        let target = targetAt100.clamped(to: 0.20 ... 1.20)
        return (target / effective).clamped(to: 0.20 ... 12.0)
    }

    static func curveGain(systemVolume: Double, points: [GainCurvePoint]) -> Double {
        let v = systemVolume.clamped(to: 0.0 ... 1.0)
        let sorted = points.sorted { $0.x < $1.x }
        guard let first = sorted.first, let last = sorted.last else { return 1.0 }
        if v <= first.x { return first.y }
        if v >= last.x { return last.y }

        for idx in 1 ..< sorted.count {
            let left = sorted[idx - 1]
            let right = sorted[idx]
            if v <= right.x {
                let t = (v - left.x) / max(0.0001, right.x - left.x)
                return left.y + (right.y - left.y) * t
            }
        }
        return last.y
    }
}
