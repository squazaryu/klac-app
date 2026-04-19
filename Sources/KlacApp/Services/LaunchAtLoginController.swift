import Foundation

protocol LaunchAtLoginControlling {
    func setEnabled(_ enabled: Bool) throws
}

struct SystemLaunchAtLoginController: LaunchAtLoginControlling {
    func setEnabled(_ enabled: Bool) throws {
        try LaunchAtLoginService.setEnabled(enabled)
    }
}
