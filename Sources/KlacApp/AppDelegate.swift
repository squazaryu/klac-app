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
    private let hostingController: NSHostingController<AnyView>
    private var eventMonitor: Any?

    init(service: KeyboardSoundService) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        popover = NSPopover()
        let rootView = AnyView(ContentView().environmentObject(service))
        hostingController = NSHostingController(rootView: rootView)
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

        popover.behavior = .transient
        popover.contentViewController = hostingController
        refreshPopoverSize()
    }

    @objc private func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            popover.performClose(sender)
            stopMonitoring()
        } else {
            guard let button = statusItem.button else { return }
            refreshPopoverSize()
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
            popover.contentViewController?.view.window?.makeMain()
            startMonitoring()
        }
    }

    private func refreshPopoverSize() {
        guard let contentView = popover.contentViewController?.view else { return }
        contentView.layoutSubtreeIfNeeded()
        let fitting = contentView.fittingSize
        guard fitting.width > 0, fitting.height > 0 else { return }
        popover.contentSize = NSSize(width: ceil(fitting.width), height: ceil(fitting.height))
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
