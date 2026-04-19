import Foundation

struct ProfileSettingsState: Equatable {
    var selectedProfile: SoundProfile
    var volume: Double
    var variation: Double
    var playKeyUp: Bool
    var pressLevel: Double
    var releaseLevel: Double
    var spaceLevel: Double
}

struct ProfileSettingsTransferService {
    func exportData(from state: ProfileSettingsState) throws -> Data {
        let snapshot = SettingsSnapshot(
            profile: state.selectedProfile.rawValue,
            volume: state.volume,
            variation: state.variation,
            playKeyUp: state.playKeyUp,
            pressLevel: state.pressLevel,
            releaseLevel: state.releaseLevel,
            spaceLevel: state.spaceLevel
        )
        return try JSONEncoder().encode(snapshot)
    }

    func importState(from data: Data, fallbackProfile: SoundProfile) throws -> ProfileSettingsState {
        let snapshot = try JSONDecoder().decode(SettingsSnapshot.self, from: data)
        return ProfileSettingsState(
            selectedProfile: SoundProfile(rawValue: snapshot.profile) ?? fallbackProfile,
            volume: snapshot.volume.clamped(to: 0.0 ... 1.0),
            variation: snapshot.variation.clamped(to: 0.0 ... 1.0),
            playKeyUp: snapshot.playKeyUp,
            pressLevel: snapshot.pressLevel.clamped(to: 0.2 ... 1.6),
            releaseLevel: snapshot.releaseLevel.clamped(to: 0.1 ... 1.4),
            spaceLevel: snapshot.spaceLevel.clamped(to: 0.2 ... 1.8)
        )
    }
}
