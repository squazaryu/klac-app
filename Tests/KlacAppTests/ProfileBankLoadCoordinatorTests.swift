#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class ProfileBankLoadCoordinatorTests: XCTestCase {
    func testCustomPackUsesCustomLoader() {
        var calls: [String] = []

        _ = ProfileBankLoadCoordinator.load(
            sourceKind: .customPack,
            loadCustomPackOrFallback: {
                calls.append("custom")
                return .empty
            },
            loadManifest: { _, _ in
                calls.append("manifest")
                return .empty
            },
            loadMechvibesConfig: { _, _ in
                calls.append("mechvibes")
                return .empty
            }
        )

        XCTAssertEqual(calls, ["custom"])
    }

    func testManifestOrMechvibesFallsBackWhenManifestEmpty() {
        var calls: [String] = []
        let source: SoundProfileSource.Kind = .manifestOrMechvibes(
            resourceDirectory: "r",
            manifestFilename: "pack.json",
            mechvibesConfigFilename: "config.json"
        )

        _ = ProfileBankLoadCoordinator.load(
            sourceKind: source,
            loadCustomPackOrFallback: {
                calls.append("custom")
                return .empty
            },
            loadManifest: { _, _ in
                calls.append("manifest")
                return .empty
            },
            loadMechvibesConfig: { _, _ in
                calls.append("mechvibes")
                return .empty
            }
        )

        XCTAssertEqual(calls, ["manifest", "mechvibes"])
    }

    func testManifestOrMechvibesKeepsManifestWhenNotEmpty() {
        var calls: [String] = []
        let source: SoundProfileSource.Kind = .manifestOrMechvibes(
            resourceDirectory: "r",
            manifestFilename: "pack.json",
            mechvibesConfigFilename: "config.json"
        )
        let nonEmptyManifest = SampleBank(
            downLayers: [.alpha: [:]],
            releaseSamples: [:]
        )

        let result = ProfileBankLoadCoordinator.load(
            sourceKind: source,
            loadCustomPackOrFallback: {
                calls.append("custom")
                return .empty
            },
            loadManifest: { _, _ in
                calls.append("manifest")
                return nonEmptyManifest
            },
            loadMechvibesConfig: { _, _ in
                calls.append("mechvibes")
                return .empty
            }
        )

        XCTAssertEqual(calls, ["manifest"])
        XCTAssertEqual(result.downLayers.keys.count, nonEmptyManifest.downLayers.keys.count)
    }
}
#endif
