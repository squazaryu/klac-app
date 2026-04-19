import Foundation

enum AutoOutputPresetKind: Equatable {
    case headphones
    case speakers
}

struct AutoOutputPresetDecision: Equatable {
    let shouldApply: Bool
    let nextLastAutoPresetDeviceUID: String?
    let presetKind: AutoOutputPresetKind?
}

enum AutoOutputPresetCoordinator {
    static func decide(
        autoOutputPresetEnabled: Bool,
        deviceUID: String,
        lastAutoPresetDeviceUID: String,
        deviceName: String
    ) -> AutoOutputPresetDecision {
        guard autoOutputPresetEnabled, !deviceUID.isEmpty else {
            return AutoOutputPresetDecision(
                shouldApply: false,
                nextLastAutoPresetDeviceUID: nil,
                presetKind: nil
            )
        }
        guard deviceUID != lastAutoPresetDeviceUID else {
            return AutoOutputPresetDecision(
                shouldApply: false,
                nextLastAutoPresetDeviceUID: nil,
                presetKind: nil
            )
        }
        let kind: AutoOutputPresetKind = OutputDeviceClassifier.looksLikeHeadphones(deviceName) ? .headphones : .speakers
        return AutoOutputPresetDecision(
            shouldApply: true,
            nextLastAutoPresetDeviceUID: deviceUID,
            presetKind: kind
        )
    }
}

