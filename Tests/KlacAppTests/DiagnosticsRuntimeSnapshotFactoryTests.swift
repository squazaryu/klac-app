#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class DiagnosticsRuntimeSnapshotFactoryTests: XCTestCase {
    func testMakeSnapshotUsesMetadataProviderAndContext() {
        let provider = MockMetadataProvider(
            appVersion: "2.1.4",
            buildNumber: "42",
            buildTag: "b42-dev",
            osVersion: "macOS 15"
        )
        let factory = DiagnosticsRuntimeSnapshotFactory(metadataProvider: provider)
        let context = DiagnosticsRuntimeContext(
            outputDeviceName: "Nothing Headphone 1",
            outputUID: "uid-123",
            accessibilityGranted: true,
            inputMonitoringGranted: false,
            capturingKeyboard: true,
            systemVolumeAvailable: true,
            systemVolumePercent: 37,
            runtimeSettings: ["- volume=0.7"],
            stressTestStatus: "running"
        )

        let snapshot = factory.makeSnapshot(context: context)

        XCTAssertEqual(snapshot.appVersion, "2.1.4")
        XCTAssertEqual(snapshot.buildNumber, "42")
        XCTAssertEqual(snapshot.buildTag, "b42-dev")
        XCTAssertEqual(snapshot.osVersion, "macOS 15")
        XCTAssertEqual(snapshot.outputDeviceName, "Nothing Headphone 1")
        XCTAssertEqual(snapshot.outputUID, "uid-123")
        XCTAssertEqual(snapshot.accessibilityGranted, true)
        XCTAssertEqual(snapshot.inputMonitoringGranted, false)
        XCTAssertEqual(snapshot.capturingKeyboard, true)
        XCTAssertEqual(snapshot.systemVolumeAvailable, true)
        XCTAssertEqual(snapshot.systemVolumePercent, 37, accuracy: 0.0001)
        XCTAssertEqual(snapshot.runtimeSettings, ["- volume=0.7"])
        XCTAssertEqual(snapshot.stressTestStatus, "running")
    }
}

private struct MockMetadataProvider: AppBuildMetadataProviding {
    let appVersion: String
    let buildNumber: String
    let buildTag: String
    let osVersion: String

    func appVersion() -> String { appVersion }
    func buildNumber() -> String { buildNumber }
    func buildTag() -> String { buildTag }
    func osVersion() -> String { osVersion }
}
#endif
