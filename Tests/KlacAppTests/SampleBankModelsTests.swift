#if canImport(XCTest)
import AVFoundation
import XCTest
@testable import KlacApp

final class SampleBankModelsTests: XCTestCase {
    private func makeBuffer() -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 2)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1)!
        buffer.frameLength = 1
        buffer.floatChannelData?[0][0] = 0
        buffer.floatChannelData?[1][0] = 0
        return buffer
    }

    func testDownSamplesFallsBackToAlphaMedium() {
        let medium = makeBuffer()
        let bank = SampleBank(
            downLayers: [.alpha: [.medium: [medium]]],
            releaseSamples: [:]
        )
        let result = bank.downSamples(for: .space, layer: .hard)
        XCTAssertEqual(result.count, 1)
    }

    func testReleasePoolFallsBackToAlpha() {
        let alpha = makeBuffer()
        let bank = SampleBank(
            downLayers: [:],
            releaseSamples: [.alpha: [alpha]]
        )
        let result = bank.releasePool(for: .delete)
        XCTAssertEqual(result.count, 1)
    }
}
#endif
