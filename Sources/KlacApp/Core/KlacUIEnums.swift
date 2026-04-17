import Foundation

enum KlacABFeature: String, CaseIterable, Identifiable {
    case core
    case compensation
    case limiter
    case adaptation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .core: return "Компенсация + Лимитер"
        case .compensation: return "Компенсация"
        case .limiter: return "Лимитер"
        case .adaptation: return "Адаптация"
        }
    }
}

enum KlacAppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "Системная"
        case .light: return "Светлая"
        case .dark: return "Темная"
        }
    }
}

enum KlacOutputPresetMode: String, CaseIterable, Identifiable {
    case auto
    case headphones
    case speakers

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto: return "Авто"
        case .headphones: return "Наушники"
        case .speakers: return "Динамики"
        }
    }
}

enum KlacLevelTuningMode: String, CaseIterable, Identifiable {
    case simple
    case curve

    var id: String { rawValue }

    var title: String {
        switch self {
        case .simple: return "Простой"
        case .curve: return "Кривая"
        }
    }
}
