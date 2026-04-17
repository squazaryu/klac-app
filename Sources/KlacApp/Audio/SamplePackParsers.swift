import Foundation

enum MechvibesDefineValue: Decodable {
    case file(String)
    case sprite([Double])
    case none

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .none
            return
        }
        if let file = try? container.decode(String.self) {
            self = .file(file)
            return
        }
        if let sprite = try? container.decode([Double].self) {
            self = .sprite(sprite)
            return
        }
        self = .none
    }
}

struct MechvibesConfig: Decodable {
    let sound: String?
    let key_define_type: String?
    let defines: [String: MechvibesDefineValue]
}

struct ManifestPack: Decodable {
    struct ManifestGroup: Decodable {
        let soft: [String]?
        let medium: [String]?
        let hard: [String]?
        let slam: [String]?
    }

    let groups: [String: ManifestGroup]
    let release: [String: [String]]?
}

enum SamplePackParsers {
    static func decodeMechvibesConfig(from data: Data) throws -> MechvibesConfig {
        try JSONDecoder().decode(MechvibesConfig.self, from: data)
    }

    static func decodeManifestPack(from data: Data) throws -> ManifestPack {
        try JSONDecoder().decode(ManifestPack.self, from: data)
    }
}
