#if canImport(XCTest)
import XCTest
@testable import KlacApp

@MainActor
final class UpdateCheckRuntimeCoordinatorTests: XCTestCase {
    func testRunIfNeededSkipsWhenAlreadyInProgress() async {
        var inProgressValues: [Bool] = []
        var statusValues: [String] = []
        var debugValues: [String] = []
        var flowCalls = 0
        var actionCalls = 0

        await UpdateCheckRuntimeCoordinator.runIfNeeded(
            isAlreadyInProgress: true,
            currentVersion: "2.1.6",
            currentBuild: 1,
            dependencies: .init(
                setInProgress: { inProgressValues.append($0) },
                setStatusText: { statusValues.append($0) },
                recordDebug: { debugValues.append($0) },
                runFlow: { _, _ in
                    flowCalls += 1
                    return UpdateCheckPresentation(statusText: "x", debugMessage: "y", action: nil)
                },
                executeAction: { _ in actionCalls += 1 }
            )
        )

        XCTAssertTrue(inProgressValues.isEmpty)
        XCTAssertTrue(statusValues.isEmpty)
        XCTAssertTrue(debugValues.isEmpty)
        XCTAssertEqual(flowCalls, 0)
        XCTAssertEqual(actionCalls, 0)
    }

    func testRunIfNeededAppliesPresentationAndExecutesAction() async {
        var inProgressValues: [Bool] = []
        var statusValues: [String] = []
        var debugValues: [String] = []
        var receivedAction: UpdateCheckUIAction?

        await UpdateCheckRuntimeCoordinator.runIfNeeded(
            isAlreadyInProgress: false,
            currentVersion: "2.1.6",
            currentBuild: 7,
            dependencies: .init(
                setInProgress: { inProgressValues.append($0) },
                setStatusText: { statusValues.append($0) },
                recordDebug: { debugValues.append($0) },
                runFlow: { version, build in
                    XCTAssertEqual(version, "2.1.6")
                    XCTAssertEqual(build, 7)
                    return UpdateCheckPresentation(
                        statusText: "Найдена версия 2.1.7",
                        debugMessage: "Update check: newer version found 2.1.7",
                        action: .showInfoAlert(title: "t", message: "m")
                    )
                },
                executeAction: { action in
                    receivedAction = action
                }
            )
        )

        XCTAssertEqual(inProgressValues, [true, false])
        XCTAssertEqual(statusValues.first, "Проверка...")
        XCTAssertEqual(statusValues.last, "Найдена версия 2.1.7")
        XCTAssertEqual(debugValues.first, "Update check started")
        XCTAssertEqual(debugValues.last, "Update check: newer version found 2.1.7")
        XCTAssertEqual(receivedAction, .showInfoAlert(title: "t", message: "m"))
    }
}
#endif
