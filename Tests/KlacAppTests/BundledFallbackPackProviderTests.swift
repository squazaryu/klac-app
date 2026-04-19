#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class BundledFallbackPackProviderTests: XCTestCase {
    func testKalihBoxWhiteContainsExpectedPrimaryPaths() {
        let paths = BundledFallbackPackProvider.kalihBoxWhite()

        XCTAssertEqual(paths.keyDown, ["Sounds/kalihboxwhite/kalihboxwhite-press_key1.mp3"])
        XCTAssertEqual(paths.keyUp, ["Sounds/kalihboxwhite/kalihboxwhite-release_key.mp3"])
        XCTAssertEqual(paths.spaceDown, ["Sounds/kalihboxwhite/kalihboxwhite-press_space.mp3"])
        XCTAssertEqual(paths.spaceUp, ["Sounds/kalihboxwhite/kalihboxwhite-release_space.mp3"])
        XCTAssertEqual(paths.enterDown, ["Sounds/kalihboxwhite/kalihboxwhite-press_enter.mp3"])
        XCTAssertEqual(paths.enterUp, ["Sounds/kalihboxwhite/kalihboxwhite-release_enter.mp3"])
        XCTAssertEqual(paths.backspaceDown, ["Sounds/kalihboxwhite/kalihboxwhite-press_back.mp3"])
        XCTAssertEqual(paths.backspaceUp, ["Sounds/kalihboxwhite/kalihboxwhite-release_back.mp3"])
    }
}
#endif
