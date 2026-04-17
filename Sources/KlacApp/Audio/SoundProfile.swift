import Foundation

enum SoundProfile: String, CaseIterable, Identifiable {
    case customPack
    case kalihBoxWhite
    case mechvibesGateronBrownsRevolt
    case mechvibesHyperXAqua
    case mechvibesBoxJade
    case mechvibesOperaGX
    case mechvibesCherryMXBlackABS
    case mechvibesCherryMXBlackPBT
    case mechvibesEGCrystalPurple
    case mechvibesEGOreo

    var id: String { rawValue }

    var title: String {
        switch self {
        case .customPack: return "Custom Pack"
        case .kalihBoxWhite: return "Kalih Box White"
        case .mechvibesGateronBrownsRevolt: return "Mechvibes: Gateron Browns - Revolt"
        case .mechvibesHyperXAqua: return "Mechvibes: HyperX Aqua"
        case .mechvibesBoxJade: return "Mechvibes: Box Jade"
        case .mechvibesOperaGX: return "Mechvibes: Opera GX"
        case .mechvibesCherryMXBlackABS: return "Mechvibes: CherryMX Black - ABS"
        case .mechvibesCherryMXBlackPBT: return "Mechvibes: CherryMX Black - PBT"
        case .mechvibesEGCrystalPurple: return "Mechvibes: EG Crystal Purple"
        case .mechvibesEGOreo: return "Mechvibes: EG Oreo"
        }
    }
}
