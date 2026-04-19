import Foundation

protocol PermissionsControlling {
    func refreshStatus(promptIfNeeded: Bool) -> PermissionsStatus
    func openAccessibilitySettings()
    func openInputMonitoringSettings()
    func resetTCC(service: String, bundleID: String)
}

struct SystemPermissionsController: PermissionsControlling {
    func refreshStatus(promptIfNeeded: Bool) -> PermissionsStatus {
        PermissionsService.refreshStatus(promptIfNeeded: promptIfNeeded)
    }

    func openAccessibilitySettings() {
        PermissionsService.openAccessibilitySettings()
    }

    func openInputMonitoringSettings() {
        PermissionsService.openInputMonitoringSettings()
    }

    func resetTCC(service: String, bundleID: String) {
        PermissionsService.resetTCC(service: service, bundleID: bundleID)
    }
}
