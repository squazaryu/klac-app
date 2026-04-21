import AppKit
import SwiftUI

private var globalStatusController: StatusBarController?

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let keyboardService = KeyboardSoundService()

    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = notification
        if let duration = parseStressDurationFromCLI() {
            Task { [weak self] in
                guard let self else { return }
                await self.keyboardService.runAutomatedStressTest(duration: duration, includeOutputRouteSimulation: true)
                NSApplication.shared.terminate(nil)
            }
            return
        }
        globalStatusController = StatusBarController(service: keyboardService)
    }

    private func parseStressDurationFromCLI() -> TimeInterval? {
        StressTestCLIParser.parseDuration(arguments: CommandLine.arguments)
    }
}

@MainActor
final class StatusBarController: NSObject {
    private var statusItem: NSStatusItem
    private let popover: NSPopover
    private let hostingController: NSHostingController<AnyView>
    private var eventMonitor: Any?
    private let menuViewModel: MenuBarViewModel
    private var statusItemSetupRetryCount = 0
    private let maxStatusItemSetupRetries = 6

    init(service: KeyboardSoundService) {
        menuViewModel = MenuBarViewModel(service: service)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        popover = NSPopover()
        let rootView = AnyView(ContentView().environmentObject(menuViewModel))
        hostingController = NSHostingController(rootView: rootView)
        super.init()

        installStatusItemButtonOrRetry()

        popover.behavior = .transient
        popover.contentViewController = hostingController
        refreshPopoverSize()
    }

    private func installStatusItemButtonOrRetry() {
        if let button = statusItem.button {
            button.title = "K"
            button.font = NSFont.systemFont(ofSize: 13, weight: .bold)
            button.action = #selector(togglePopover(_:))
            button.target = self
            statusItem.isVisible = true
            statusItemSetupRetryCount = 0
            NSLog("Status item created. buttonVisible=\(statusItem.isVisible)")
            return
        }

        guard statusItemSetupRetryCount < maxStatusItemSetupRetries else {
            NSLog("Failed to create status bar button after retries")
            return
        }

        statusItemSetupRetryCount += 1
        NSLog("Status item button unavailable, retry #\(statusItemSetupRetryCount)")

        // Recreate item before retrying to avoid a stale NSStatusItem reference.
        NSStatusBar.system.removeStatusItem(statusItem)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self else { return }
            self.installStatusItemButtonOrRetry()
        }
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
