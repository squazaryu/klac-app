#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class PersistentDebugLogServiceTests: XCTestCase {
    func testBeginSessionDetectsPreviousUngracefulExit() {
        let suite = "klac.tests.persistentlog.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let service = PersistentDebugLogService(defaults: defaults)
        XCTAssertFalse(service.beginSession(appVersion: "2.1.6", buildNumber: 214))

        let serviceSecondRun = PersistentDebugLogService(defaults: defaults)
        XCTAssertTrue(serviceSecondRun.beginSession(appVersion: "2.1.6", buildNumber: 214))

        serviceSecondRun.markGracefulShutdown()
    }

    func testRotationDoesNotCrashOnLargeLogBurst() {
        let suite = "klac.tests.persistentlog.rotate.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let service = PersistentDebugLogService(defaults: defaults, maxLogBytes: 200_000, maxArchives: 2)
        _ = service.beginSession(appVersion: "2.1.6", buildNumber: 214)
        let payload = String(repeating: "x", count: 6_000)
        for _ in 0 ..< 80 {
            service.append(payload)
        }
        service.markGracefulShutdown()
    }
}
#endif
