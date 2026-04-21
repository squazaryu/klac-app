import Foundation

struct AccessRecoveryResetDependencies {
    let resolveBundleID: () -> String?
    let resetTCC: (String, String) -> Void
    let openAccessibilitySettings: () -> Void
    let openInputMonitoringSettings: () -> Void
    let schedulePostResetRefresh: (@escaping () -> Void) -> Void
    let refreshStatus: () -> Void
}

struct AccessRecoveryWizardDependencies {
    let runResetFlow: () -> Void
    let setHint: (String) -> Void
    let scheduleWizard: (
        @escaping () -> Void,
        @escaping () -> Void,
        @escaping () -> Void
    ) -> Void
    let openSettings: () -> Void
    let restartApplication: () -> Void
}

enum AccessRecoveryRuntimeCoordinator {
    @discardableResult
    static func runResetFlow(
        dependencies: AccessRecoveryResetDependencies
    ) -> (bundleID: String, hint: String)? {
        guard let bundleID = dependencies.resolveBundleID() else {
            return nil
        }
        let plan = AccessRecoveryPlanCoordinator.makePlan()
        for service in plan.tccServicesToReset {
            dependencies.resetTCC(service, bundleID)
        }
        dependencies.openAccessibilitySettings()
        dependencies.openInputMonitoringSettings()
        dependencies.schedulePostResetRefresh {
            dependencies.refreshStatus()
        }
        return (bundleID: bundleID, hint: plan.postResetHint)
    }

    static func runWizardFlow(dependencies: AccessRecoveryWizardDependencies) {
        dependencies.runResetFlow()
        let plan = AccessRecoveryPlanCoordinator.makePlan()
        dependencies.scheduleWizard(
            { dependencies.openSettings() },
            { dependencies.setHint(plan.wizardHint) },
            { dependencies.restartApplication() }
        )
    }
}
