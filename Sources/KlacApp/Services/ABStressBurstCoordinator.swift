import Foundation

struct ABStressBurstDependencies {
    let playDown: (Int) -> Void
    let playUp: (Int) -> Void
    let sleep: (UInt64) async -> Void
}

enum ABStressBurstCoordinator {
    static let defaultKeys: [Int] = [49, 36, 51, 0, 49]
    static let defaultStepSleepNs: UInt64 = 65_000_000

    static func run(
        keys: [Int] = defaultKeys,
        playKeyUp: Bool,
        dependencies: ABStressBurstDependencies
    ) async {
        for key in keys {
            dependencies.playDown(key)
            if playKeyUp {
                dependencies.playUp(key)
            }
            await dependencies.sleep(defaultStepSleepNs)
        }
    }
}
