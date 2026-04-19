import Foundation

enum CustomPackFallbackCoordinator {
    static func load(
        customPackRoot: URL?,
        defaultCustomPackDirectory: () -> URL,
        installCustomPack: (URL) -> Bool,
        currentBank: () -> SampleBank,
        fallbackBank: () -> SampleBank
    ) -> SampleBank {
        if let root = customPackRoot, installCustomPack(root) {
            return currentBank()
        }
        let fallbackRoot = defaultCustomPackDirectory()
        if installCustomPack(fallbackRoot) {
            return currentBank()
        }
        return fallbackBank()
    }
}
