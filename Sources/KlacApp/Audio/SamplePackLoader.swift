import AVFoundation
import Foundation

struct SamplePackLoader {
    let format: AVAudioFormat
    let pitchVariationAmount: Float
    let onManifestValidation: ((String, [String]) -> Void)?
    let diagnostic: ((String) -> Void)?

    func loadBank(
        keyDown: [String],
        keyUp: [String],
        spaceDown: [String],
        spaceUp: [String],
        enterDown: [String],
        enterUp: [String],
        backspaceDown: [String],
        backspaceUp: [String],
        fallback: SampleBank
    ) -> SampleBank {
        let variantCount = 2
        let alphaDown = expandSamples(keyDown.compactMap(loadPCMBuffer(resourcePath:)), variantsPerSample: variantCount)
        let alphaUp = expandSamples(keyUp.compactMap(loadPCMBuffer(resourcePath:)), variantsPerSample: variantCount)
        let spaceDownPool = expandSamples(spaceDown.compactMap(loadPCMBuffer(resourcePath:)), variantsPerSample: variantCount)
        let spaceUpPool = expandSamples(spaceUp.compactMap(loadPCMBuffer(resourcePath:)), variantsPerSample: variantCount)
        let enterDownPool = expandSamples(enterDown.compactMap(loadPCMBuffer(resourcePath:)), variantsPerSample: variantCount)
        let enterUpPool = expandSamples(enterUp.compactMap(loadPCMBuffer(resourcePath:)), variantsPerSample: variantCount)
        let deleteDownPool = expandSamples(backspaceDown.compactMap(loadPCMBuffer(resourcePath:)), variantsPerSample: variantCount)
        let deleteUpPool = expandSamples(backspaceUp.compactMap(loadPCMBuffer(resourcePath:)), variantsPerSample: variantCount)

        guard !alphaDown.isEmpty else {
            NSLog("No keyboard sample files loaded for selected profile")
            return fallback
        }
        var downLayers: [KeyGroup: [VelocityLayer: [AVAudioPCMBuffer]]] = [:]
        for group in KeyGroup.allCases {
            downLayers[group] = [.medium: alphaDown]
        }
        downLayers[.space] = [.medium: spaceDownPool.isEmpty ? alphaDown : spaceDownPool]
        downLayers[.enter] = [.medium: enterDownPool.isEmpty ? alphaDown : enterDownPool]
        downLayers[.delete] = [.medium: deleteDownPool.isEmpty ? alphaDown : deleteDownPool]

        var releaseSamples: [KeyGroup: [AVAudioPCMBuffer]] = [:]
        for group in KeyGroup.allCases {
            releaseSamples[group] = alphaUp
        }
        if !spaceUpPool.isEmpty { releaseSamples[.space] = spaceUpPool }
        if !enterUpPool.isEmpty { releaseSamples[.enter] = enterUpPool }
        if !deleteUpPool.isEmpty { releaseSamples[.delete] = deleteUpPool }

        return SampleBank(downLayers: downLayers, releaseSamples: releaseSamples)
    }

    func loadBankFromDirectory(_ root: URL, fallback: SampleBank) -> SampleBank {
        let exts = ["wav", "mp3", "m4a", "aif", "aiff"]
        func files(prefixes: [String]) -> [URL] {
            guard let all = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else { return [] }
            let lower = all.map { $0 }.filter { exts.contains($0.pathExtension.lowercased()) }
            let matched = lower.filter { url in
                let name = url.deletingPathExtension().lastPathComponent.lowercased()
                return prefixes.contains { name.hasPrefix($0) }
            }.sorted { $0.lastPathComponent < $1.lastPathComponent }
            return matched
        }

        return loadBank(
            keyDown: files(prefixes: ["key-down", "press-key", "keydown"]).map(\.path),
            keyUp: files(prefixes: ["key-up", "release-key", "keyup"]).map(\.path),
            spaceDown: files(prefixes: ["space-down", "press-space"]).map(\.path),
            spaceUp: files(prefixes: ["space-up", "release-space"]).map(\.path),
            enterDown: files(prefixes: ["enter-down", "press-enter"]).map(\.path),
            enterUp: files(prefixes: ["enter-up", "release-enter"]).map(\.path),
            backspaceDown: files(prefixes: ["backspace-down", "press-back"]).map(\.path),
            backspaceUp: files(prefixes: ["backspace-up", "release-back"]).map(\.path),
            fallback: fallback
        )
    }

    func loadBankFromMechvibesConfig(resourceDirectory: String, configFilename: String, fallback: SampleBank) -> SampleBank {
        let configPath = "\(resourceDirectory)/\(configFilename)"
        guard let configURL = resolveResourceURL(path: configPath) else {
            NSLog("Missing Mechvibes config: \(configPath)")
            return fallback
        }

        let config: MechvibesConfig
        do {
            let data = try Data(contentsOf: configURL)
            config = try SamplePackParsers.decodeMechvibesConfig(from: data)
        } catch {
            NSLog("Failed to decode Mechvibes config \(configPath): \(error)")
            return fallback
        }

        let isMulti = (config.key_define_type ?? "single") == "multi"

        func stringFile(for keyCode: Int) -> String? {
            guard let value = config.defines[String(keyCode)] else { return nil }
            if case let .file(file) = value, !file.isEmpty { return file }
            return nil
        }

        func spriteSlice(for keyCode: Int) -> (startMs: Double, durationMs: Double)? {
            guard let value = config.defines[String(keyCode)] else { return nil }
            if case let .sprite(bounds) = value, bounds.count >= 2 {
                return (startMs: bounds[0], durationMs: bounds[1])
            }
            return nil
        }

        if !isMulti, let sound = config.sound, !sound.isEmpty {
            let fullPath = "\(resourceDirectory)/\(sound)"
            if let base = loadPCMBuffer(resourcePath: fullPath) {
                let allSlices = config.defines.compactMap { pair -> AVAudioPCMBuffer? in
                    guard let key = Int(pair.key) else { return nil }
                    guard let (startMs, durationMs) = spriteSlice(for: key) else { return nil }
                    return slicePCMBuffer(base, startMs: startMs, durationMs: durationMs)
                }
                if !allSlices.isEmpty {
                    func slices(for codes: [Int]) -> [AVAudioPCMBuffer] {
                        let selected = codes.compactMap { code -> AVAudioPCMBuffer? in
                            guard let (startMs, durationMs) = spriteSlice(for: code) else { return nil }
                            return slicePCMBuffer(base, startMs: startMs, durationMs: durationMs)
                        }
                        if !selected.isEmpty { return selected }
                        return Array(allSlices.prefix(8))
                    }

                    let alphaCodes = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]
                    let spaceCodes = [49]
                    let enterCodes = [36, 76, 28]
                    let deleteCodes = [51, 117, 14]

                    let alphaDown = expandSamples(slices(for: alphaCodes), variantsPerSample: 1)
                    let spaceDown = expandSamples(slices(for: spaceCodes), variantsPerSample: 1)
                    let enterDown = expandSamples(slices(for: enterCodes), variantsPerSample: 1)
                    let deleteDown = expandSamples(slices(for: deleteCodes), variantsPerSample: 1)

                    var downLayers: [KeyGroup: [VelocityLayer: [AVAudioPCMBuffer]]] = [:]
                    for group in KeyGroup.allCases {
                        downLayers[group] = [.medium: alphaDown]
                    }
                    if !spaceDown.isEmpty { downLayers[.space] = [.medium: spaceDown] }
                    if !enterDown.isEmpty { downLayers[.enter] = [.medium: enterDown] }
                    if !deleteDown.isEmpty { downLayers[.delete] = [.medium: deleteDown] }

                    var release: [KeyGroup: [AVAudioPCMBuffer]] = [:]
                    for group in KeyGroup.allCases {
                        release[group] = alphaDown
                    }
                    if !spaceDown.isEmpty { release[.space] = spaceDown }
                    if !enterDown.isEmpty { release[.enter] = enterDown }
                    if !deleteDown.isEmpty { release[.delete] = deleteDown }

                    return boostedIfQuiet(SampleBank(downLayers: downLayers, releaseSamples: release))
                }
            }
        }

        var keyDownFiles: [String] = []
        if isMulti {
            let allFiles = config.defines.values.compactMap { value -> String? in
                if case let .file(file) = value, !file.isEmpty { return file }
                return nil
            }
            keyDownFiles = Array(Set(allFiles)).sorted()
        } else if let sound = config.sound, !sound.isEmpty {
            keyDownFiles = [sound]
        }

        let fallbackFile = keyDownFiles.first
        let spaceFile = stringFile(for: 57) ?? fallbackFile
        let enterFile = stringFile(for: 28) ?? fallbackFile
        let backspaceFile = stringFile(for: 14) ?? fallbackFile

        func prefixed(_ file: String?) -> [String] {
            guard let file, !file.isEmpty else { return [] }
            return ["\(resourceDirectory)/\(file)"]
        }

        let raw = loadBank(
            keyDown: keyDownFiles.map { "\(resourceDirectory)/\($0)" },
            keyUp: keyDownFiles.map { "\(resourceDirectory)/\($0)" },
            spaceDown: prefixed(spaceFile),
            spaceUp: prefixed(spaceFile),
            enterDown: prefixed(enterFile),
            enterUp: prefixed(enterFile),
            backspaceDown: prefixed(backspaceFile),
            backspaceUp: prefixed(backspaceFile),
            fallback: fallback
        )
        return boostedIfQuiet(raw)
    }

    func loadBankFromManifest(resourceDirectory: String, configFilename: String = "pack.json", fallback: SampleBank) -> SampleBank {
        let configPath = "\(resourceDirectory)/\(configFilename)"
        guard let configURL = resolveResourceURL(path: configPath) else {
            NSLog("Missing manifest pack config: \(configPath)")
            onManifestValidation?("Манифест не найден: \(configFilename)", ["missing file \(configPath)"])
            return fallback
        }

        let manifest: ManifestPack
        do {
            let data = try Data(contentsOf: configURL)
            manifest = try SamplePackParsers.decodeManifestPack(from: data)
        } catch {
            NSLog("Failed to decode manifest pack \(configPath): \(error)")
            onManifestValidation?("Ошибка чтения манифеста: \(configFilename)", ["\(error.localizedDescription)"])
            return fallback
        }

        var downLayers: [KeyGroup: [VelocityLayer: [AVAudioPCMBuffer]]] = [:]
        var validationErrors: [String] = []

        func validatedPaths(_ paths: [String], context: String) -> [String] {
            var out: [String] = []
            for rel in paths {
                let resourcePath = "\(resourceDirectory)/\(rel)"
                if resolveResourceURL(path: resourcePath) == nil {
                    validationErrors.append("missing file '\(rel)' for \(context)")
                    continue
                }
                out.append(resourcePath)
            }
            return out
        }

        for group in KeyGroup.allCases {
            guard let source = manifest.groups[group.rawValue] else { continue }
            var layers: [VelocityLayer: [AVAudioPCMBuffer]] = [:]
            for layer in VelocityLayer.allCases {
                let paths: [String]
                switch layer {
                case .soft: paths = source.soft ?? []
                case .medium: paths = source.medium ?? []
                case .hard: paths = source.hard ?? []
                case .slam: paths = source.slam ?? []
                }
                let resolvedPaths = validatedPaths(paths, context: "\(group.rawValue).\(layer.rawValue)")
                let loaded = expandSamples(resolvedPaths.compactMap(loadPCMBuffer(resourcePath:)), variantsPerSample: 1)
                if !loaded.isEmpty {
                    layers[layer] = loaded
                }
            }
            if !layers.isEmpty {
                downLayers[group] = layers
            }
        }

        var releaseSamples: [KeyGroup: [AVAudioPCMBuffer]] = [:]
        if let release = manifest.release {
            for group in KeyGroup.allCases {
                guard let paths = release[group.rawValue] else { continue }
                let resolvedPaths = validatedPaths(paths, context: "release.\(group.rawValue)")
                let loaded = expandSamples(resolvedPaths.compactMap(loadPCMBuffer(resourcePath:)), variantsPerSample: 1)
                if !loaded.isEmpty {
                    releaseSamples[group] = loaded
                }
            }
        }

        if downLayers[.alpha] == nil { validationErrors.append("missing group 'alpha'") }
        if downLayers[.space] == nil { validationErrors.append("missing group 'space'") }
        if downLayers[.enter] == nil { validationErrors.append("missing group 'enter'") }
        if downLayers[.delete] == nil { validationErrors.append("missing group 'delete'") }

        if !validationErrors.isEmpty {
            for issue in validationErrors {
                NSLog("Manifest pack validation issue (\(configPath)): \(issue)")
            }
            onManifestValidation?("Манифест загружен с предупреждениями", validationErrors)
        } else {
            onManifestValidation?("Манифест OK: \(configFilename)", [])
        }

        let loaded = SampleBank(downLayers: downLayers, releaseSamples: releaseSamples)
        guard !loaded.downSamples(for: .alpha, layer: .medium).isEmpty || !loaded.downLayers.isEmpty else {
            NSLog("Manifest pack has no usable down samples: \(configPath)")
            onManifestValidation?("Манифест пустой", ["no usable down samples in \(configFilename)"])
            return fallback
        }
        return boostedIfQuiet(loaded)
    }

    func diagnostic(_ message: String) {
        if let diagnostic {
            diagnostic(message)
        } else {
            NSLog("KlacAudio: \(message)")
        }
    }

    static func defaultCustomPackDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("Klac/SoundPacks/Custom", isDirectory: true)
    }

    static func resolveRoot(for directory: URL) -> URL {
        let manifestNames = ["key-down", "press-key", "keydown"]
        guard let items = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return directory }
        let hasSamples = items.contains { item in
            let name = item.deletingPathExtension().lastPathComponent.lowercased()
            return manifestNames.contains { name.hasPrefix($0) }
        }
        if hasSamples { return directory }
        if let nested = items.first(where: { $0.hasDirectoryPath }) {
            return nested
        }
        return directory
    }

    private func slicePCMBuffer(_ base: AVAudioPCMBuffer, startMs: Double, durationMs: Double) -> AVAudioPCMBuffer? {
        let sr = base.format.sampleRate
        let startFrame = max(0, Int((startMs / 1000.0) * sr))
        let frameCount = max(1, Int((durationMs / 1000.0) * sr))
        let totalFrames = Int(base.frameLength)
        guard startFrame < totalFrames else { return nil }
        let available = max(1, min(frameCount, totalFrames - startFrame))
        guard let out = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(available)) else { return nil }
        out.frameLength = AVAudioFrameCount(available)
        let channels = Int(format.channelCount)
        for ch in 0 ..< channels {
            guard let src = base.floatChannelData?[ch], let dst = out.floatChannelData?[ch] else { continue }
            for i in 0 ..< available {
                dst[i] = src[startFrame + i]
            }
        }
        return out
    }

    private func boostedIfQuiet(_ bank: SampleBank) -> SampleBank {
        let measuredPeak = max(
            peak(of: bank.downLayers.values.flatMap { $0.values.flatMap { $0 } }),
            peak(of: bank.releaseSamples.values.flatMap { $0 })
        )
        guard measuredPeak > 0 else { return bank }
        let targetPeak: Float = 0.78
        let gain = (targetPeak / measuredPeak).clamped(to: 1.0 ... 5.0)
        if gain <= 1.05 { return bank }
        NSLog("Boosting quiet sound pack by x\(String(format: "%.2f", gain)) (peak=\(String(format: "%.3f", measuredPeak)))")
        var boostedDown: [KeyGroup: [VelocityLayer: [AVAudioPCMBuffer]]] = [:]
        for (group, layers) in bank.downLayers {
            var boostedLayers: [VelocityLayer: [AVAudioPCMBuffer]] = [:]
            for (layer, buffers) in layers {
                boostedLayers[layer] = applyGain(buffers, gain: gain)
            }
            boostedDown[group] = boostedLayers
        }
        var boostedRelease: [KeyGroup: [AVAudioPCMBuffer]] = [:]
        for (group, buffers) in bank.releaseSamples {
            boostedRelease[group] = applyGain(buffers, gain: gain)
        }
        return SampleBank(downLayers: boostedDown, releaseSamples: boostedRelease)
    }

    private func peak(of buffers: [AVAudioPCMBuffer]) -> Float {
        var m: Float = 0
        for buffer in buffers {
            let frames = Int(buffer.frameLength)
            let channels = Int(buffer.format.channelCount)
            for ch in 0 ..< channels {
                guard let data = buffer.floatChannelData?[ch] else { continue }
                for i in 0 ..< frames {
                    m = max(m, abs(data[i]))
                }
            }
        }
        return m
    }

    private func applyGain(_ buffers: [AVAudioPCMBuffer], gain: Float) -> [AVAudioPCMBuffer] {
        buffers.compactMap { buffer in
            guard let out = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: buffer.frameCapacity) else { return nil }
            out.frameLength = buffer.frameLength
            let frames = Int(buffer.frameLength)
            let channels = Int(format.channelCount)
            for ch in 0 ..< channels {
                guard let src = buffer.floatChannelData?[ch],
                      let dst = out.floatChannelData?[ch] else { continue }
                for i in 0 ..< frames {
                    dst[i] = (src[i] * gain).clamped(to: -1.0 ... 1.0)
                }
            }
            return out
        }
    }

    private func expandSamples(_ source: [AVAudioPCMBuffer], variantsPerSample: Int) -> [AVAudioPCMBuffer] {
        guard !source.isEmpty else { return [] }
        var out: [AVAudioPCMBuffer] = []
        for base in source {
            out.append(base)
            for _ in 0 ..< variantsPerSample {
                if let v = makeVariant(from: base) {
                    out.append(v)
                }
            }
        }
        return out
    }

    private func makeVariant(from base: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        let amt = Double(pitchVariationAmount.clamped(to: 0 ... 0.6))
        let jitter = 0.015 + amt * 0.06
        let rateJitter = Double.random(in: -jitter ... jitter)
        let rate = max(0.9, min(1.1, 1.0 + rateJitter))
        let transient = Float.random(in: 0.92 ... 1.08)
        let tail = Float.random(in: 0.94 ... 1.04)
        return resample(buffer: base, rate: rate, transient: transient, tail: tail)
    }

    private func resample(buffer: AVAudioPCMBuffer, rate: Double, transient: Float, tail: Float) -> AVAudioPCMBuffer? {
        let frames = Int(buffer.frameLength)
        guard frames > 1 else { return nil }
        guard let out = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: buffer.frameCapacity) else { return nil }
        out.frameLength = buffer.frameLength

        let channels = Int(format.channelCount)
        for ch in 0 ..< channels {
            guard let src = buffer.floatChannelData?[ch],
                  let dst = out.floatChannelData?[ch] else { continue }
            for i in 0 ..< frames {
                let pos = Double(i) * rate
                let i0 = min(frames - 1, Int(pos))
                let i1 = min(frames - 1, i0 + 1)
                let frac = Float(pos - Double(i0))
                let sample = src[i0] * (1 - frac) + src[i1] * frac
                let t = Float(i) / Float(frames)
                let shape = (t < 0.25 ? transient : tail)
                dst[i] = sample * shape
            }
        }
        return out
    }

    private func loadPCMBuffer(resourcePath: String) -> AVAudioPCMBuffer? {
        if resourcePath.hasPrefix("/") {
            return loadPCMBuffer(fileURL: URL(fileURLWithPath: resourcePath))
        }
        guard let url = resolveResourceURL(path: resourcePath) else {
            NSLog("Missing audio resource: \(resourcePath)")
            return nil
        }

        do {
            let file = try AVAudioFile(forReading: url)
            let inFormat = file.processingFormat
            guard let sourceBuffer = AVAudioPCMBuffer(pcmFormat: inFormat, frameCapacity: AVAudioFrameCount(file.length)) else {
                return nil
            }
            try file.read(into: sourceBuffer)

            if inFormat.sampleRate == format.sampleRate,
               inFormat.channelCount == format.channelCount {
                return sourceBuffer
            }

            return convert(sourceBuffer: sourceBuffer, from: inFormat, to: format)
        } catch {
            NSLog("Failed to load sample \(resourcePath): \(error)")
            return nil
        }
    }

    private func resolveResourceURL(path: String) -> URL? {
        guard let baseURL = Bundle.module.resourceURL else { return nil }
        let requested = path as NSString
        let filename = requested.lastPathComponent
        let nsFilename = filename as NSString
        var candidates: [URL] = []

        let directURL = baseURL.appendingPathComponent(path)
        let flatURL = baseURL.appendingPathComponent(filename)
        let bundleURL = Bundle.module.url(
            forResource: nsFilename.deletingPathExtension,
            withExtension: nsFilename.pathExtension
        )
        candidates.append(contentsOf: [directURL, flatURL, bundleURL].compactMap { $0 })

        if requested.pathExtension.lowercased() == "ogg" {
            let wavRelative = requested.deletingPathExtension + ".wav"
            let wavFilename = (wavRelative as NSString).lastPathComponent
            let wavDirect = baseURL.appendingPathComponent(wavRelative)
            let wavFlat = baseURL.appendingPathComponent(wavFilename)
            let wavBundle = Bundle.module.url(
                forResource: (wavFilename as NSString).deletingPathExtension,
                withExtension: "wav"
            )
            candidates.append(contentsOf: [wavDirect, wavFlat, wavBundle].compactMap { $0 })
        }

        return candidates.first {
            FileManager.default.fileExists(atPath: $0.path)
        }
    }

    private func loadPCMBuffer(fileURL: URL) -> AVAudioPCMBuffer? {
        do {
            let file = try AVAudioFile(forReading: fileURL)
            let inFormat = file.processingFormat
            guard let sourceBuffer = AVAudioPCMBuffer(pcmFormat: inFormat, frameCapacity: AVAudioFrameCount(file.length)) else {
                return nil
            }
            try file.read(into: sourceBuffer)
            if inFormat.sampleRate == format.sampleRate,
               inFormat.channelCount == format.channelCount {
                return sourceBuffer
            }
            return convert(sourceBuffer: sourceBuffer, from: inFormat, to: format)
        } catch {
            NSLog("Failed to load custom sample \(fileURL.path): \(error)")
            return nil
        }
    }

    private func convert(sourceBuffer: AVAudioPCMBuffer, from inFormat: AVAudioFormat, to outFormat: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let converter = AVAudioConverter(from: inFormat, to: outFormat) else { return nil }
        let ratio = outFormat.sampleRate / inFormat.sampleRate
        let capacity = AVAudioFrameCount(Double(sourceBuffer.frameLength) * ratio + 64)
        guard let outBuffer = AVAudioPCMBuffer(pcmFormat: outFormat, frameCapacity: capacity) else { return nil }

        var didProvideInput = false
        let status = converter.convert(to: outBuffer, error: nil) { _, outStatus in
            if didProvideInput {
                outStatus.pointee = .noDataNow
                return nil
            }
            didProvideInput = true
            outStatus.pointee = .haveData
            return sourceBuffer
        }
        return status == .haveData || status == .inputRanDry ? outBuffer : nil
    }
}
