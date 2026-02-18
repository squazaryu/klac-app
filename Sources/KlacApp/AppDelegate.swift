import AppKit
import SwiftUI

private var globalStatusController: StatusBarController?

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let keyboardService = KeyboardSoundService()

    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = notification
        globalStatusController = StatusBarController(service: keyboardService)
    }
}

final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private var eventMonitor: Any?

    init(service: KeyboardSoundService) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        popover = NSPopover()
        super.init()

        if let button = statusItem.button {
            button.title = "K"
            button.font = NSFont.systemFont(ofSize: 13, weight: .bold)
            button.action = #selector(togglePopover(_:))
            button.target = self
            statusItem.isVisible = true
            NSLog("Status item created. buttonVisible=\(statusItem.isVisible)")
        } else {
            NSLog("Failed to create status bar button")
        }

        let view = ContentView()
            .environmentObject(service)
            .frame(width: 356, height: 390)

        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: view)
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            popover.performClose(sender)
            stopMonitoring()
        } else {
            guard let button = statusItem.button else { return }
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            startMonitoring()
        }
    }

    private func startMonitoring() {
        stopMonitoring()
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, self.popover.isShown else { return }
            if let button = self.statusItem.button,
               event.window != button.window {
                self.popover.performClose(nil)
                self.stopMonitoring()
            }
        }
    }

    private func stopMonitoring() {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
    }
}
