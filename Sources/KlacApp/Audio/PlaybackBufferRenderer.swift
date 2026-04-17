import AVFoundation
import Foundation

enum PlaybackBufferRenderer {
    static func makePlayableCopy(
        from buffer: AVAudioPCMBuffer,
        format: AVAudioFormat,
        gain: Float,
        variation: Float,
        limiterEnabled: Bool,
        limiterDrive: Float
    ) -> AVAudioPCMBuffer? {
        guard let copy = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: buffer.frameCapacity) else { return nil }
        copy.frameLength = buffer.frameLength

        let channels = Int(format.channelCount)
        let frames = Int(buffer.frameLength)
        let panJitter = Float.random(in: -1 ... 1) * variation * 0.14

        for channel in 0 ..< channels {
            guard let src = buffer.floatChannelData?[channel],
                  let dst = copy.floatChannelData?[channel] else { continue }
            let channelPanGain: Float
            if channels >= 2 {
                channelPanGain = channel == 0 ? (1.0 - max(0, panJitter)) : (1.0 + min(0, panJitter))
            } else {
                channelPanGain = 1.0
            }
            for i in 0 ..< frames {
                let pre = src[i] * gain * channelPanGain
                if limiterEnabled {
                    let drive = max(0.6, limiterDrive)
                    let shaped = Float(tanh(Double(pre * drive)) / tanh(Double(drive)))
                    let mix = ((drive - 0.6) / 1.4).clamped(to: 0.0 ... 1.0)
                    dst[i] = pre * (1 - mix) + shaped * mix
                } else {
                    dst[i] = pre.clamped(to: -1.0 ... 1.0)
                }
            }
        }
        return copy
    }
}
