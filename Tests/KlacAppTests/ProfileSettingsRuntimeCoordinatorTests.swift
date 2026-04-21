#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class ProfileSettingsRuntimeCoordinatorTests: XCTestCase {
    func testMakeExportStateMapsValues() {
        let source = ProfileSettingsExportSource(
            selectedProfile: .mechvibesBoxJade,
            volume: 0.7,
            variation: 0.2,
            playKeyUp: false,
            pressLevel: 1.1,
            releaseLevel: 0.6,
            spaceLevel: 1.0
        )

        let state = ProfileSettingsRuntimeCoordinator.makeExportState(from: source)

        XCTAssertEqual(state.selectedProfile, .mechvibesBoxJade)
        XCTAssertEqual(state.volume, 0.7, accuracy: 0.0001)
        XCTAssertEqual(state.playKeyUp, false)
    }

    func testRunImportAppliesImportedStateAndLogsViaRuntimeResultCoordinator() {
        var applied = false
        var logs: [String] = []
        let imported = ProfileSettingsState(
            selectedProfile: .kalihBoxWhite,
            volume: 0.5,
            variation: 0.3,
            playKeyUp: true,
            pressLevel: 1.0,
            releaseLevel: 0.65,
            spaceLevel: 1.1
        )
        let deps = ProfileSettingsRuntimeDependencies(
            exportSettings: { _ in .cancelled },
            importSettings: { _ in (.success(path: "/tmp/in.json"), imported) },
            applyImportedSettings: { _ in applied = true },
            recordDebug: { logs.append($0) }
        )

        ProfileSettingsRuntimeCoordinator.runImport(fallbackProfile: .customPack, dependencies: deps)

        XCTAssertTrue(applied)
        XCTAssertEqual(logs, ["Settings imported: /tmp/in.json"])
    }
}
#endif
