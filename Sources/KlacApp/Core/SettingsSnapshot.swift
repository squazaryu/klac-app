import Foundation

struct SettingsSnapshot: Codable {
    let profile: String
    let volume: Double
    let variation: Double
    let playKeyUp: Bool
    let pressLevel: Double
    let releaseLevel: Double
    let spaceLevel: Double
}
