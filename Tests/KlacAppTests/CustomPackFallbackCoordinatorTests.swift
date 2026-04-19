#if canImport(XCTest)
import XCTest
@testable import KlacApp

final class CustomPackFallbackCoordinatorTests: XCTestCase {
    func testUsesCustomRootWhenInstallSucceeds() {
        let custom = URL(fileURLWithPath: "/tmp/custom")
        let fallback = URL(fileURLWithPath: "/tmp/fallback")
        var installCalls: [URL] = []
        let marker = SampleBank(downLayers: [.alpha: [:]], releaseSamples: [:])

        let result = CustomPackFallbackCoordinator.load(
            customPackRoot: custom,
            defaultCustomPackDirectory: { fallback },
            installCustomPack: { url in
                installCalls.append(url)
                return url == custom
            },
            currentBank: { marker },
            fallbackBank: { .empty }
        )

        XCTAssertEqual(installCalls, [custom])
        XCTAssertEqual(result.downLayers.keys.count, marker.downLayers.keys.count)
    }

    func testUsesFallbackRootWhenCustomFails() {
        let custom = URL(fileURLWithPath: "/tmp/custom")
        let fallback = URL(fileURLWithPath: "/tmp/fallback")
        var installCalls: [URL] = []
        let marker = SampleBank(downLayers: [.space: [:]], releaseSamples: [:])

        let result = CustomPackFallbackCoordinator.load(
            customPackRoot: custom,
            defaultCustomPackDirectory: { fallback },
            installCustomPack: { url in
                installCalls.append(url)
                return url == fallback
            },
            currentBank: { marker },
            fallbackBank: { .empty }
        )

        XCTAssertEqual(installCalls, [custom, fallback])
        XCTAssertEqual(result.downLayers.keys.count, marker.downLayers.keys.count)
    }

    func testFallsBackToBundledBankWhenBothInstallsFail() {
        let custom = URL(fileURLWithPath: "/tmp/custom")
        let fallback = URL(fileURLWithPath: "/tmp/fallback")
        var installCalls: [URL] = []
        let bundled = SampleBank(downLayers: [.enter: [:]], releaseSamples: [:])

        let result = CustomPackFallbackCoordinator.load(
            customPackRoot: custom,
            defaultCustomPackDirectory: { fallback },
            installCustomPack: { url in
                installCalls.append(url)
                return false
            },
            currentBank: { .empty },
            fallbackBank: { bundled }
        )

        XCTAssertEqual(installCalls, [custom, fallback])
        XCTAssertEqual(result.downLayers.keys.count, bundled.downLayers.keys.count)
    }
}
#endif
