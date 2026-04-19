import Foundation

protocol RecoveryScheduling {
    func schedule(after delay: TimeInterval, _ block: @escaping () -> Void)
}

struct MainQueueRecoveryScheduler: RecoveryScheduling {
    func schedule(after delay: TimeInterval, _ block: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: block)
    }
}

struct AccessRecoveryCoordinator {
    private let scheduler: RecoveryScheduling

    init(scheduler: RecoveryScheduling = MainQueueRecoveryScheduler()) {
        self.scheduler = scheduler
    }

    func schedulePostResetRefresh(_ refresh: @escaping () -> Void) {
        scheduler.schedule(after: 0.6, refresh)
    }

    func scheduleWizard(openSettings: @escaping () -> Void, setHint: @escaping () -> Void, restart: @escaping () -> Void) {
        scheduler.schedule(after: 0.5) {
            openSettings()
            setHint()
        }
        scheduler.schedule(after: 1.1, restart)
    }
}

