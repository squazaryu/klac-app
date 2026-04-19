import Foundation

enum PerDevicePersistenceCoordinator {
    static func canPersistSnapshot(
        perDeviceSoundProfileEnabled: Bool,
        deviceUID: String
    ) -> Bool {
        perDeviceSoundProfileEnabled && !deviceUID.isEmpty
    }

    static func canPersistBoost(deviceUID: String) -> Bool {
        !deviceUID.isEmpty
    }
}
