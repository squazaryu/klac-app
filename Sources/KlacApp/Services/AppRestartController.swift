import AppKit
import Foundation

protocol AppRestartControlling {
    func restartApplication(onManualRestartRequired: @escaping () -> Void)
}

struct SystemAppRestartController: AppRestartControlling {
    func restartApplication(onManualRestartRequired: @escaping () -> Void) {
        if let appURL = AppMetadataService.resolveAppBundleURL() {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = false
            config.createsNewApplicationInstance = true
            NSWorkspace.shared.openApplication(at: appURL, configuration: config) { _, error in
                if let error {
                    NSLog("Primary relaunch failed: \(error). Falling back to detached open.")
                    DispatchQueue.main.async {
                        Self.relaunchWithDetachedOpen(appURL: appURL)
                    }
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    NSApplication.shared.terminate(nil)
                }
            }
            return
        }

        // Development run (e.g. `swift run`) without a .app bundle.
        guard let executableURL = Bundle.main.executableURL else {
            NSLog("Failed to resolve app bundle or executable URL for relaunch")
            return
        }
        if Self.relaunchWithDetachedExecutable(executableURL: executableURL) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                NSApplication.shared.terminate(nil)
            }
        } else {
            onManualRestartRequired()
        }
    }

    private static func relaunchWithDetachedOpen(appURL: URL) {
        let escapedPath = appURL.path.replacingOccurrences(of: "'", with: "'\\''")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/nohup")
        process.arguments = ["/bin/sh", "-c", "sleep 0.35; /usr/bin/open -n '\(escapedPath)'"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                NSApplication.shared.terminate(nil)
            }
        } catch {
            NSLog("Detached relaunch failed: \(error)")
        }
    }

    private static func relaunchWithDetachedExecutable(executableURL: URL) -> Bool {
        let escapedPath = executableURL.path.replacingOccurrences(of: "'", with: "'\\''")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/nohup")
        process.arguments = ["/bin/sh", "-c", "sleep 0.35; '\(escapedPath)' >/dev/null 2>&1 &"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            return true
        } catch {
            NSLog("Detached executable relaunch failed: \(error)")
            return false
        }
    }
}
