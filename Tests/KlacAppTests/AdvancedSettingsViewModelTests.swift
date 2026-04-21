#if canImport(XCTest)
import Combine
import XCTest
@testable import KlacApp

@MainActor
final class AdvancedSettingsViewModelTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    func testReadsInitialValuesFromService() {
        let service = MockAdvancedSettingsService()
        service.doubleStorage[.volume] = 0.42
        service.boolStorage[.limiterEnabled] = true
        service.stringValues.debugLogPreview = "hello"

        let viewModel = AdvancedSettingsViewModel(service: service)

        XCTAssertEqual(viewModel.binding(.volume).wrappedValue, 0.42, accuracy: 0.0001)
        XCTAssertTrue(viewModel.limiterEnabled)
        XCTAssertEqual(viewModel.debugLogPreview, "hello")
    }

    func testWriteBindingsInvokeServiceSetters() {
        let service = MockAdvancedSettingsService()
        let viewModel = AdvancedSettingsViewModel(service: service)

        viewModel.binding(.volume).wrappedValue = 0.77
        viewModel.binding(.playKeyUp).wrappedValue = false
        viewModel.binding(.appearanceMode).wrappedValue = .dark

        XCTAssertEqual(service.lastSetDouble?.key, .volume)
        XCTAssertEqual(service.lastSetDouble?.value, 0.77, accuracy: 0.0001)
        XCTAssertEqual(service.lastSetBool?.key, .playKeyUp)
        XCTAssertEqual(service.lastSetBool?.value, false)
        XCTAssertEqual(service.appearanceMode, .dark)
    }

    func testCommandMethodsDelegateExactlyOnce() {
        let service = MockAdvancedSettingsService()
        let viewModel = AdvancedSettingsViewModel(service: service)

        viewModel.playABComparison()
        viewModel.applyHeadphonesPreset()
        viewModel.applySpeakersPreset()
        viewModel.refreshAccessibilityStatus(promptIfNeeded: true)
        viewModel.runAccessRecoveryWizard()
        viewModel.exportSettings()
        viewModel.importSettings()
        viewModel.startStressTest(duration: 12)
        viewModel.exportDebugLog()
        viewModel.clearDebugLog()

        XCTAssertEqual(service.playABComparisonCalls, 1)
        XCTAssertEqual(service.applyHeadphonesPresetCalls, 1)
        XCTAssertEqual(service.applySpeakersPresetCalls, 1)
        XCTAssertEqual(service.refreshAccessCalls, 1)
        XCTAssertEqual(service.recoveryCalls, 1)
        XCTAssertEqual(service.exportSettingsCalls, 1)
        XCTAssertEqual(service.importSettingsCalls, 1)
        XCTAssertEqual(service.startStressTestCalls, 1)
        XCTAssertEqual(service.exportDebugLogCalls, 1)
        XCTAssertEqual(service.clearDebugLogCalls, 1)
    }

    func testChangePublisherPropagatesToObjectWillChange() {
        let service = MockAdvancedSettingsService()
        let viewModel = AdvancedSettingsViewModel(service: service)
        let expectation = expectation(description: "objectWillChange propagated")

        viewModel.objectWillChange
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        service.emitChange()
        wait(for: [expectation], timeout: 0.2)
    }
}

@MainActor
private final class MockAdvancedSettingsService: AdvancedSettingsServiceProtocol {
    struct StringValues {
        var profilePresetLastApplied = "preset"
        var liveVelocityLayer = "medium"
        var manifestValidationSummary = "ok"
        var currentOutputDeviceName = "device"
        var autoOutputPresetLastApplied = "—"
        var stressTestStatus = "idle"
        var debugLogPreview = ""
    }

    private let changeSubject = PassthroughSubject<Void, Never>()
    var changePublisher: AnyPublisher<Void, Never> { changeSubject.eraseToAnyPublisher() }
    var boolStorage: [AdvancedBoolSetting: Bool] = [:]
    var doubleStorage: [AdvancedDoubleSetting: Double] = [:]
    var abFeature: KlacABFeature = .core
    var levelTuningMode: KlacLevelTuningMode = .curve
    var outputPresetMode: KlacOutputPresetMode = .auto
    var appearanceMode: KlacAppearanceMode = .system
    var stringValues = StringValues()
    var manifestValidationIssues: [String] = []
    var detectedSystemVolumeAvailable = true
    var detectedSystemVolumePercent = 55.0
    var stressTestInProgress = false
    var stressTestProgress = 0.0
    var isABPlaying = false

    var playABComparisonCalls = 0
    var applyHeadphonesPresetCalls = 0
    var applySpeakersPresetCalls = 0
    var refreshAccessCalls = 0
    var recoveryCalls = 0
    var exportSettingsCalls = 0
    var importSettingsCalls = 0
    var startStressTestCalls = 0
    var exportDebugLogCalls = 0
    var clearDebugLogCalls = 0

    var lastSetBool: (key: AdvancedBoolSetting, value: Bool)?
    var lastSetDouble: (key: AdvancedDoubleSetting, value: Double)?

    func boolValue(_ key: AdvancedBoolSetting) -> Bool {
        boolStorage[key] ?? false
    }

    func setBool(_ value: Bool, for key: AdvancedBoolSetting) {
        boolStorage[key] = value
        lastSetBool = (key, value)
    }

    func doubleValue(_ key: AdvancedDoubleSetting) -> Double {
        doubleStorage[key] ?? 0
    }

    func setDouble(_ value: Double, for key: AdvancedDoubleSetting) {
        doubleStorage[key] = value
        lastSetDouble = (key, value)
    }

    func enumValue<T>(_ setting: AdvancedEnumSetting<T>) -> T where T: RawRepresentable {
        switch setting.key {
        case .abFeature:
            return abFeature as! T
        case .levelTuningMode:
            return levelTuningMode as! T
        case .outputPresetMode:
            return outputPresetMode as! T
        case .appearanceMode:
            return appearanceMode as! T
        }
    }

    func setEnum<T>(_ value: T, for setting: AdvancedEnumSetting<T>) where T: RawRepresentable {
        switch setting.key {
        case .abFeature:
            abFeature = value as! KlacABFeature
        case .levelTuningMode:
            levelTuningMode = value as! KlacLevelTuningMode
        case .outputPresetMode:
            outputPresetMode = value as! KlacOutputPresetMode
        case .appearanceMode:
            appearanceMode = value as! KlacAppearanceMode
        }
    }

    var profilePresetLastApplied: String { stringValues.profilePresetLastApplied }
    var liveDynamicGain: Double { doubleStorage[.compensationStrength] ?? 1.0 }
    var liveTypingGain: Double { 1.0 }
    var typingCPS: Double { 2.0 }
    var typingWPM: Double { 25.0 }
    var liveVelocityLayer: String { stringValues.liveVelocityLayer }
    var manifestValidationSummary: String { stringValues.manifestValidationSummary }
    var currentOutputDeviceName: String { stringValues.currentOutputDeviceName }
    var autoOutputPresetLastApplied: String { stringValues.autoOutputPresetLastApplied }
    var stressTestStatus: String { stringValues.stressTestStatus }
    var debugLogPreview: String { stringValues.debugLogPreview }

    func playABComparison() { playABComparisonCalls += 1 }
    func applyHeadphonesPreset() { applyHeadphonesPresetCalls += 1 }
    func applySpeakersPreset() { applySpeakersPresetCalls += 1 }
    func autoInverseGainPreview(systemVolumePercent: Double) -> Double { systemVolumePercent / 100.0 }
    func refreshAccessibilityStatus(promptIfNeeded _: Bool) { refreshAccessCalls += 1 }
    func runAccessRecoveryWizard() { recoveryCalls += 1 }
    func exportSettings() { exportSettingsCalls += 1 }
    func importSettings() { importSettingsCalls += 1 }
    func startStressTest(duration _: TimeInterval) { startStressTestCalls += 1 }
    func exportDebugLog() { exportDebugLogCalls += 1 }
    func clearDebugLog() { clearDebugLogCalls += 1 }

    func emitChange() {
        changeSubject.send(())
    }
}
#endif
