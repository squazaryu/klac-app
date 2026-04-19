import Foundation

struct ProfilePresetDecision {
    let settings: SoundSettings?
    let label: String
}

enum ProfilePresetCoordinator {
    static func decide(for profile: SoundProfile) -> ProfilePresetDecision {
        guard let preset = SoundPresetService.profilePreset(for: profile) else {
            return ProfilePresetDecision(settings: nil, label: "Базовый пресет")
        }
        return ProfilePresetDecision(settings: preset.settings, label: preset.label)
    }
}
