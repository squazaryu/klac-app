#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class DiagnosticsRuntimeContextMapperTests: XCTestCase {
    func testMapUsesFallbackForEmptyUID() {
        let context = DiagnosticsRuntimeContextMapper.map(.init(
            outputDeviceName: "Device",
            outputUID: "",
            accessibilityGranted: true,
            inputMonitoringGranted: false,
            capturingKeyboard: true,
            systemVolumeAvailable: true,
            systemVolumePercent: 43,
            runtimeSettings: ["a=b"],
            stressTestStatus: "ok"
        ))

        XCTAssertEqual(context.outputUID, "n/a")
    }

    func testMapPassesFieldsAsIsWhenUIDExists() {
        let context = DiagnosticsRuntimeContextMapper.map(.init(
            outputDeviceName: "USB DAC",
            outputUID: "uid-123",
            accessibilityGranted: false,
            inputMonitoringGranted: true,
            capturingKeyboard: false,
            systemVolumeAvailable: false,
            systemVolumePercent: 0,
            runtimeSettings: ["x=y"],
            stressTestStatus: "idle"
        ))

        XCTAssertEqual(context.outputDeviceName, "USB DAC")
        XCTAssertEqual(context.outputUID, "uid-123")
        XCTAssertEqual(context.accessibilityGranted, false)
        XCTAssertEqual(context.inputMonitoringGranted, true)
        XCTAssertEqual(context.capturingKeyboard, false)
        XCTAssertEqual(context.systemVolumeAvailable, false)
        XCTAssertEqual(context.systemVolumePercent, 0, accuracy: 0.0001)
        XCTAssertEqual(context.runtimeSettings, ["x=y"])
        XCTAssertEqual(context.stressTestStatus, "idle")
    }
}
#endif
