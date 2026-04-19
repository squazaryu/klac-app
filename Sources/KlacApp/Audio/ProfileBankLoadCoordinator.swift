import Foundation

enum ProfileBankLoadCoordinator {
    static func load(
        sourceKind: SoundProfileSource.Kind,
        loadCustomPackOrFallback: () -> SampleBank,
        loadManifest: (_ resourceDirectory: String, _ configFilename: String) -> SampleBank,
        loadMechvibesConfig: (_ resourceDirectory: String, _ configFilename: String) -> SampleBank
    ) -> SampleBank {
        switch sourceKind {
        case .customPack:
            return loadCustomPackOrFallback()
        case let .manifestOnly(resourceDirectory, configFilename):
            return loadManifest(resourceDirectory, configFilename)
        case let .manifestOrMechvibes(resourceDirectory, manifestFilename, mechvibesConfigFilename):
            let manifest = loadManifest(resourceDirectory, manifestFilename)
            if !manifest.downLayers.isEmpty {
                return manifest
            }
            return loadMechvibesConfig(resourceDirectory, mechvibesConfigFilename)
        case let .mechvibesConfig(resourceDirectory, configFilename):
            return loadMechvibesConfig(resourceDirectory, configFilename)
        }
    }
}
