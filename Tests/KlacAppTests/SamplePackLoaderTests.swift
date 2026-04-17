#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class SamplePackLoaderTests: XCTestCase {
    func testDefaultCustomPackDirectoryHasExpectedSuffix() {
        let dir = SamplePackLoader.defaultCustomPackDirectory().path
        XCTAssertTrue(dir.contains("Application Support"))
        XCTAssertTrue(dir.hasSuffix("/Klac/SoundPacks/Custom"))
    }

    func testResolveRootReturnsNestedFolderWhenTopHasNoSamples() throws {
        let base = FileManager.default.temporaryDirectory
            .appendingPathComponent("KlacTests-\(UUID().uuidString)", isDirectory: true)
        let nested = base.appendingPathComponent("NestedPack", isDirectory: true)
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        try "x".write(to: nested.appendingPathComponent("readme.txt"), atomically: true, encoding: .utf8)

        defer { try? FileManager.default.removeItem(at: base) }

        let resolved = SamplePackLoader.resolveRoot(for: base)
        XCTAssertEqual(resolved.lastPathComponent, "NestedPack")
    }
}
#endif
