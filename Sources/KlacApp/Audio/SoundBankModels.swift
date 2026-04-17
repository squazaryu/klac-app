import AVFoundation
import Foundation

enum KeyGroup: String, CaseIterable {
    case alpha
    case modifier
    case function
    case arrow
    case space
    case enter
    case delete
    case other
}

enum VelocityLayer: String, CaseIterable {
    case soft
    case medium
    case hard
    case slam
}

struct SampleBank {
    var downLayers: [KeyGroup: [VelocityLayer: [AVAudioPCMBuffer]]]
    var releaseSamples: [KeyGroup: [AVAudioPCMBuffer]]

    static var empty: SampleBank {
        SampleBank(downLayers: [:], releaseSamples: [:])
    }

    func downSamples(for group: KeyGroup, layer: VelocityLayer) -> [AVAudioPCMBuffer] {
        if let exact = downLayers[group]?[layer], !exact.isEmpty { return exact }
        if let medium = downLayers[group]?[.medium], !medium.isEmpty { return medium }
        if let alpha = downLayers[.alpha]?[layer], !alpha.isEmpty { return alpha }
        if let alphaMedium = downLayers[.alpha]?[.medium], !alphaMedium.isEmpty { return alphaMedium }
        return []
    }

    func releasePool(for group: KeyGroup) -> [AVAudioPCMBuffer] {
        if let exact = releaseSamples[group], !exact.isEmpty { return exact }
        if let alpha = releaseSamples[.alpha], !alpha.isEmpty { return alpha }
        return []
    }
}
