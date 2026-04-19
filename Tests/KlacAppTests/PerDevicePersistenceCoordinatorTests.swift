#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class PerDevicePersistenceCoordinatorTests: XCTestCase {
    func testCanPersistSnapshotRequiresFlagAndUID() {
        XCTAssertFalse(PerDevicePersistenceCoordinator.canPersistSnapshot(
            perDeviceSoundProfileEnabled: false,
            deviceUID: "uid"
        ))
        XCTAssertFalse(PerDevicePersistenceCoordinator.canPersistSnapshot(
            perDeviceSoundProfileEnabled: true,
            deviceUID: ""
        ))
        XCTAssertTrue(PerDevicePersistenceCoordinator.canPersistSnapshot(
            perDeviceSoundProfileEnabled: true,
            deviceUID: "uid"
        ))
    }

    func testCanPersistBoostRequiresUID() {
        XCTAssertFalse(PerDevicePersistenceCoordinator.canPersistBoost(deviceUID: ""))
        XCTAssertTrue(PerDevicePersistenceCoordinator.canPersistBoost(deviceUID: "uid"))
    }
}
#endif
