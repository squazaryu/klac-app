import Foundation

struct StressTestResult {
    let elapsed: TimeInterval
    let downHits: Int
    let upHits: Int
    let routeRebuilds: Int
}

enum StressTestService {
    static let defaultKeyCodes = [0, 1, 2, 6, 7, 8, 12, 13, 14, 31, 35, 37, 38, 40, 41, 45, 46, 49, 36, 51, 123, 124, 125, 126]

    static func run(
        duration: TimeInterval,
        includeOutputRouteSimulation: Bool,
        keyCodes: [Int] = defaultKeyCodes,
        onProgress: @MainActor @escaping (Double) -> Void,
        onDown: @MainActor @escaping (_ keyCode: Int, _ autorepeat: Bool) -> Void,
        onUp: @MainActor @escaping (_ keyCode: Int) -> Void,
        onRouteRebuild: @MainActor @escaping () -> Void
    ) async -> StressTestResult {
        let startedAt = CFAbsoluteTimeGetCurrent()
        var downHits = 0
        var upHits = 0
        var routeRebuilds = 0
        let effectiveDuration = duration.clamped(to: 5 ... 180)
        let codes = keyCodes.isEmpty ? defaultKeyCodes : keyCodes

        while (CFAbsoluteTimeGetCurrent() - startedAt) < effectiveDuration {
            let keyCode = codes.randomElement() ?? 0
            let autorepeat = Int.random(in: 0 ... 100) < 7

            await onDown(keyCode, autorepeat)
            downHits += 1

            if Int.random(in: 0 ... 100) < 75 {
                await onUp(keyCode)
                upHits += 1
            }

            if includeOutputRouteSimulation, downHits % 180 == 0 {
                await onRouteRebuild()
                routeRebuilds += 1
            }

            let elapsed = CFAbsoluteTimeGetCurrent() - startedAt
            await onProgress(min(1, elapsed / effectiveDuration))

            let sleepNs = UInt64(Int.random(in: 800_000 ... 4_200_000))
            try? await Task.sleep(nanoseconds: sleepNs)
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - startedAt
        return StressTestResult(
            elapsed: elapsed,
            downHits: downHits,
            upHits: upHits,
            routeRebuilds: routeRebuilds
        )
    }
}
