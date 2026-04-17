import AppKit
import ApplicationServices
import Foundation

struct PermissionsStatus {
    let accessibilityGranted: Bool
    let inputMonitoringGranted: Bool
}

enum PermissionsService {
    static func refreshStatus(promptIfNeeded: Bool) -> PermissionsStatus {
        let accessibilityGranted: Bool
        if promptIfNeeded {
            let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
            accessibilityGranted = AXIsProcessTrustedWithOptions(options)
        } else {
            accessibilityGranted = AXIsProcessTrusted()
        }

        let inputMonitoringGranted = preflightInputMonitoring(promptIfNeeded: promptIfNeeded)
        return PermissionsStatus(
            accessibilityGranted: accessibilityGranted,
            inputMonitoringGranted: inputMonitoringGranted
        )
    }

    static func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }

    static func openInputMonitoringSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") else { return }
        NSWorkspace.shared.open(url)
    }

    static func resetTCC(service: String, bundleID: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        process.arguments = ["reset", service, bundleID]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            NSLog("Failed to reset TCC \(service): \(error)")
        }
    }

    private static func preflightInputMonitoring(promptIfNeeded: Bool) -> Bool {
        let preflight = CGPreflightListenEventAccess()
        if preflight || !promptIfNeeded {
            return preflight
        }
        return CGRequestListenEventAccess()
    }
}
