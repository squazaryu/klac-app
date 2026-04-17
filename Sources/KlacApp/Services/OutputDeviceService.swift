import CoreAudio
import Foundation

struct OutputDeviceState {
    let deviceID: AudioObjectID
    let uid: String
    let name: String
}

enum OutputDeviceService {
    static func resolveDefaultOutputDeviceState() -> OutputDeviceState? {
        guard let deviceID = readDefaultOutputDeviceID() else { return nil }
        let uid = readOutputDeviceUID(deviceID) ?? ""
        let name = readOutputDeviceName(deviceID) ?? "Системное устройство"
        return OutputDeviceState(deviceID: deviceID, uid: uid, name: name)
    }

    static func readSystemOutputVolume() -> Double? {
        guard let deviceID = readDefaultOutputDeviceID() else { return nil }
        return readDeviceVolumeScalar(deviceID)
    }

    static func readDeviceVolumeScalar(_ deviceID: AudioObjectID) -> Double? {
        func readScalar(selector: AudioObjectPropertySelector, scope: AudioObjectPropertyScope, element: AudioObjectPropertyElement) -> Double? {
            var address = AudioObjectPropertyAddress(
                mSelector: selector,
                mScope: scope,
                mElement: element
            )
            guard AudioObjectHasProperty(deviceID, &address) else { return nil }
            var volume = Float32(0)
            var size = UInt32(MemoryLayout<Float32>.size)
            let status = AudioObjectGetPropertyData(
                deviceID,
                &address,
                0,
                nil,
                &size,
                &volume
            )
            guard status == noErr else { return nil }
            return Double(volume).clamped(to: 0.0 ... 1.0)
        }

        let attempts: [(AudioObjectPropertySelector, AudioObjectPropertyScope, AudioObjectPropertyElement)] = [
            (kAudioDevicePropertyVolumeScalar, kAudioDevicePropertyScopeOutput, kAudioObjectPropertyElementMain),
            (kAudioDevicePropertyVolumeScalar, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMain)
        ]
        for (selector, scope, element) in attempts {
            if let value = readScalar(selector: selector, scope: scope, element: element) {
                return value
            }
        }

        let channels: [UInt32] = [1, 2]
        var values: [Double] = []
        for channel in channels {
            if let value = readScalar(
                selector: kAudioDevicePropertyVolumeScalar,
                scope: kAudioDevicePropertyScopeOutput,
                element: channel
            ) {
                values.append(value)
            } else if let value = readScalar(
                selector: kAudioDevicePropertyVolumeScalar,
                scope: kAudioObjectPropertyScopeGlobal,
                element: channel
            ) {
                values.append(value)
            }
        }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    static func readDefaultOutputDeviceID() -> AudioObjectID? {
        var deviceID = AudioObjectID(0)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        return (status == noErr && deviceID != 0) ? deviceID : nil
    }

    static func readOutputDeviceUID(_ deviceID: AudioObjectID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var rawValue: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        let status = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &size,
            &rawValue
        )
        guard status == noErr, let rawValue else { return nil }
        return rawValue.takeUnretainedValue() as String
    }

    static func readOutputDeviceName(_ deviceID: AudioObjectID) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var rawValue: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        let status = AudioObjectGetPropertyData(
            deviceID,
            &address,
            0,
            nil,
            &size,
            &rawValue
        )
        guard status == noErr, let rawValue else { return nil }
        return rawValue.takeUnretainedValue() as String
    }
}
