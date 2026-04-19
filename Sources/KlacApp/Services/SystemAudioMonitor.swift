import CoreAudio
import Foundation

struct SystemAudioPollPayload {
    let scalar: Double?
    let deviceID: AudioObjectID
    let deviceUID: String
    let deviceName: String
}

@MainActor
protocol SystemAudioMonitoring: AnyObject {
    func start(interval: TimeInterval, onPoll: @escaping (SystemAudioPollPayload) -> Void)
    func stop()
    func ensureInterval(_ interval: TimeInterval, onPoll: @escaping (SystemAudioPollPayload) -> Void)
    func resetStuckPollIfNeeded(now: CFAbsoluteTime, threshold: TimeInterval) -> Bool
}

@MainActor
final class SystemAudioMonitor: SystemAudioMonitoring {
    private var timer: Timer?
    private var monitorInterval: TimeInterval = 0
    private let monitorQueue = DispatchQueue(label: "Klac.SystemAudioMonitor", qos: .utility)
    private var pollInFlight = false
    private var lastPollStartedAt: CFAbsoluteTime = 0
    private var onPoll: ((SystemAudioPollPayload) -> Void)?

    func start(interval: TimeInterval, onPoll: @escaping (SystemAudioPollPayload) -> Void) {
        self.onPoll = onPoll
        timer?.invalidate()
        monitorInterval = interval
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.poll()
            }
        }
        poll()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func ensureInterval(_ interval: TimeInterval, onPoll: @escaping (SystemAudioPollPayload) -> Void) {
        if timer == nil || abs(monitorInterval - interval) > 0.001 {
            start(interval: interval, onPoll: onPoll)
        } else {
            self.onPoll = onPoll
        }
    }

    func resetStuckPollIfNeeded(now: CFAbsoluteTime, threshold: TimeInterval) -> Bool {
        guard pollInFlight, lastPollStartedAt > 0 else { return false }
        let pollStall = now - lastPollStartedAt
        guard pollStall > threshold else { return false }
        pollInFlight = false
        lastPollStartedAt = 0
        return true
    }

    private func poll() {
        if pollInFlight { return }
        pollInFlight = true
        lastPollStartedAt = CFAbsoluteTimeGetCurrent()
        monitorQueue.async { [weak self] in
            let scalar = OutputDeviceService.readSystemOutputVolume()
            let outputState = OutputDeviceService.resolveDefaultOutputDeviceState()
            let payload = SystemAudioPollPayload(
                scalar: scalar,
                deviceID: outputState?.deviceID ?? 0,
                deviceUID: outputState?.uid ?? "",
                deviceName: outputState?.name ?? "Системное устройство"
            )

            Task { @MainActor [weak self] in
                guard let self else { return }
                defer {
                    self.pollInFlight = false
                    self.lastPollStartedAt = 0
                }
                self.onPoll?(payload)
            }
        }
    }
}
