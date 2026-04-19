#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class AudioEngineFailSafeCoordinatorTests: XCTestCase {
    func testDisabledKeepEngineReturnsNone() {
        let action = AudioEngineFailSafeCoordinator.decide(
            keepEngineRunning: false,
            engineRunning: false,
            playerPlaying: false,
            hadRecentPlayback: true
        )
        XCTAssertEqual(action, .none)
    }

    func testRequestsEngineRestartWhenEngineStopped() {
        let action = AudioEngineFailSafeCoordinator.decide(
            keepEngineRunning: true,
            engineRunning: false,
            playerPlaying: false,
            hadRecentPlayback: true
        )
        XCTAssertEqual(action, .restartEngine)
    }

    func testRequestsPlayerResumeWhenEngineRunningButPlayerStoppedAndRecentPlayback() {
        let action = AudioEngineFailSafeCoordinator.decide(
            keepEngineRunning: true,
            engineRunning: true,
            playerPlaying: false,
            hadRecentPlayback: true
        )
        XCTAssertEqual(action, .resumePlayer)
    }

    func testReturnsNoneWhenEngineAndPlayerHealthy() {
        let action = AudioEngineFailSafeCoordinator.decide(
            keepEngineRunning: true,
            engineRunning: true,
            playerPlaying: true,
            hadRecentPlayback: true
        )
        XCTAssertEqual(action, .none)
    }
}
#endif
