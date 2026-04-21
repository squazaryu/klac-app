#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class ABStressBurstCoordinatorTests: XCTestCase {
    func testRunWithKeyUpEmitsDownUpSleepForEachKey() async {
        var events: [String] = []

        await ABStressBurstCoordinator.run(
            keys: [1, 2],
            playKeyUp: true,
            dependencies: ABStressBurstDependencies(
                playDown: { events.append("down:\($0)") },
                playUp: { events.append("up:\($0)") },
                sleep: { _ in events.append("sleep") }
            )
        )

        XCTAssertEqual(events, ["down:1", "up:1", "sleep", "down:2", "up:2", "sleep"])
    }

    func testRunWithoutKeyUpSkipsUpEvents() async {
        var events: [String] = []

        await ABStressBurstCoordinator.run(
            keys: [7],
            playKeyUp: false,
            dependencies: ABStressBurstDependencies(
                playDown: { events.append("down:\($0)") },
                playUp: { events.append("up:\($0)") },
                sleep: { _ in events.append("sleep") }
            )
        )

        XCTAssertEqual(events, ["down:7", "sleep"])
    }
}
#endif
