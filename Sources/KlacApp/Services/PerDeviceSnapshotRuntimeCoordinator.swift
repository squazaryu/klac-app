import Foundation

struct PerDeviceSnapshotRuntimeCoordinator {
    private var snapshotService: PerDeviceSnapshotService

    init(snapshotService: PerDeviceSnapshotService) {
        self.snapshotService = snapshotService
    }

    func loadBoost(deviceUID: String) -> Double {
        snapshotService.boost(for: deviceUID)
    }

    mutating func persistBoostIfNeeded(currentOutputDeviceBoost: Double, deviceUID: String) {
        guard PerDevicePersistenceCoordinator.canPersistBoost(deviceUID: deviceUID) else { return }
        snapshotService.setBoost(currentOutputDeviceBoost, for: deviceUID)
    }

    mutating func persistSnapshotIfNeeded(
        perDeviceSoundProfileEnabled: Bool,
        deviceUID: String,
        source: DeviceSoundStateSource
    ) {
        guard PerDevicePersistenceCoordinator.canPersistSnapshot(
            perDeviceSoundProfileEnabled: perDeviceSoundProfileEnabled,
            deviceUID: deviceUID
        ) else { return }
        snapshotService.saveSnapshot(deviceUID: deviceUID, state: DeviceSoundStateMapper.toDTO(source))
    }

    mutating func persistCurrentDeviceState(
        perDeviceSoundProfileEnabled: Bool,
        deviceUID: String,
        currentOutputDeviceBoost: Double,
        source: DeviceSoundStateSource
    ) {
        persistBoostIfNeeded(
            currentOutputDeviceBoost: currentOutputDeviceBoost,
            deviceUID: deviceUID
        )
        persistSnapshotIfNeeded(
            perDeviceSoundProfileEnabled: perDeviceSoundProfileEnabled,
            deviceUID: deviceUID,
            source: source
        )
    }

    func restoreSnapshotPatchIfAvailable(deviceUID: String) -> SoundStatePatch? {
        var patch: SoundStatePatch?
        let restored = snapshotService.restoreSnapshot(deviceUID: deviceUID) { snapshot in
            patch = SoundStatePatchMapper.deviceSnapshotPatch(from: snapshot)
        }
        return restored ? patch : nil
    }
}
