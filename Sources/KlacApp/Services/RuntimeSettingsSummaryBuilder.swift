import Foundation

struct RuntimeSettingsSummaryInput {
    let selectedProfileRawValue: String
    let sound: SoundSettings
    let compensation: CompensationSettings
    let typingAdaptiveEnabled: Bool
    let system: SystemSettings
}

enum RuntimeSettingsSummaryBuilder {
    static func build(_ input: RuntimeSettingsSummaryInput) -> [String] {
        [
            "- profile=\(input.selectedProfileRawValue)",
            "- volume=\(String(format: "%.3f", input.sound.volume))",
            "- variation=\(String(format: "%.3f", input.sound.variation))",
            "- pitchVariation=\(String(format: "%.3f", input.sound.pitchVariation))",
            "- pressLevel=\(String(format: "%.3f", input.sound.pressLevel))",
            "- releaseLevel=\(String(format: "%.3f", input.sound.releaseLevel))",
            "- spaceLevel=\(String(format: "%.3f", input.sound.spaceLevel))",
            "- dynamicCompensationEnabled=\(input.compensation.dynamicCompensationEnabled)",
            "- strictVolumeNormalizationEnabled=\(input.compensation.strictVolumeNormalizationEnabled)",
            "- typingAdaptiveEnabled=\(input.typingAdaptiveEnabled)",
            "- stackModeEnabled=\(input.sound.stackModeEnabled)",
            "- limiterEnabled=\(input.sound.limiterEnabled)",
            "- autoOutputPresetEnabled=\(input.system.autoOutputPresetEnabled)",
            "- perDeviceSoundProfileEnabled=\(input.system.perDeviceSoundProfileEnabled)",
        ]
    }
}

