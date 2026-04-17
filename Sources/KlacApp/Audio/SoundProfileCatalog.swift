import Foundation

struct SoundProfileSource {
    enum Kind {
        case customPack
        case manifestOnly(resourceDirectory: String, configFilename: String)
        case manifestOrMechvibes(
            resourceDirectory: String,
            manifestFilename: String,
            mechvibesConfigFilename: String
        )
        case mechvibesConfig(resourceDirectory: String, configFilename: String)
    }

    let kind: Kind

    static func resolve(for profile: SoundProfile) -> SoundProfileSource {
        switch profile {
        case .customPack:
            return SoundProfileSource(kind: .customPack)
        case .kalihBoxWhite:
            return SoundProfileSource(
                kind: .manifestOnly(
                    resourceDirectory: "Sounds/kalihboxwhite",
                    configFilename: "pack-kalihboxwhite.json"
                )
            )
        case .mechvibesGateronBrownsRevolt:
            return SoundProfileSource(
                kind: .manifestOrMechvibes(
                    resourceDirectory: "Sounds/mv-gateron-browns-revolt",
                    manifestFilename: "pack-gateron-browns-revolt.json",
                    mechvibesConfigFilename: "config-gateron-browns-revolt.json"
                )
            )
        case .mechvibesHyperXAqua:
            return SoundProfileSource(
                kind: .manifestOrMechvibes(
                    resourceDirectory: "Sounds/mv-hyperx-aqua",
                    manifestFilename: "pack-hyperx-aqua.json",
                    mechvibesConfigFilename: "config-hyperx-aqua.json"
                )
            )
        case .mechvibesBoxJade:
            return SoundProfileSource(
                kind: .manifestOrMechvibes(
                    resourceDirectory: "Sounds/mv-boxjade",
                    manifestFilename: "pack-boxjade.json",
                    mechvibesConfigFilename: "config-boxjade.json"
                )
            )
        case .mechvibesOperaGX:
            return SoundProfileSource(
                kind: .manifestOrMechvibes(
                    resourceDirectory: "Sounds/mv-opera-gx",
                    manifestFilename: "pack-opera-gx.json",
                    mechvibesConfigFilename: "config-opera-gx.json"
                )
            )
        case .mechvibesCherryMXBlackABS:
            return SoundProfileSource(
                kind: .mechvibesConfig(
                    resourceDirectory: "Sounds/mv-cherrymx-black-abs",
                    configFilename: "config-cherrymx-black-abs.json"
                )
            )
        case .mechvibesCherryMXBlackPBT:
            return SoundProfileSource(
                kind: .mechvibesConfig(
                    resourceDirectory: "Sounds/mv-cherrymx-black-pbt",
                    configFilename: "config-cherrymx-black-pbt.json"
                )
            )
        case .mechvibesEGCrystalPurple:
            return SoundProfileSource(
                kind: .mechvibesConfig(
                    resourceDirectory: "Sounds/mv-eg-crystal-purple",
                    configFilename: "config-eg-crystal-purple.json"
                )
            )
        case .mechvibesEGOreo:
            return SoundProfileSource(
                kind: .mechvibesConfig(
                    resourceDirectory: "Sounds/mv-eg-oreo",
                    configFilename: "config-eg-oreo.json"
                )
            )
        }
    }
}
