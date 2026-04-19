import Foundation

protocol KeyboardInputMonitoring: AnyObject {
    var onEvent: ((KeyEventType, Int, Bool) -> Void)? { get set }
    func start() -> Bool
    func stop()
}

extension GlobalKeyEventTap: KeyboardInputMonitoring {}

@MainActor
final class KeyboardInputMonitorCoordinator {
    private let monitor: KeyboardInputMonitoring

    init(monitor: KeyboardInputMonitoring) {
        self.monitor = monitor
    }

    func setEventHandler(_ handler: @escaping (KeyEventType, Int, Bool) -> Void) {
        monitor.onEvent = handler
    }

    func start() -> Bool {
        monitor.start()
    }

    func stop() {
        monitor.stop()
    }

    func recoverIfNeeded(
        isEnabled: Bool,
        accessibilityGranted: Bool,
        inputMonitoringGranted: Bool,
        currentlyCapturing: Bool
    ) -> Bool {
        guard isEnabled else { return currentlyCapturing }
        guard !currentlyCapturing else { return currentlyCapturing }
        guard accessibilityGranted, inputMonitoringGranted else { return currentlyCapturing }
        return monitor.start()
    }
}
