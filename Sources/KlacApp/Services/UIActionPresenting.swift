import AppKit
import Foundation

protocol InfoAlertPresenting {
    func showInfoAlert(title: String, message: String)
}

struct SystemInfoAlertPresenter: InfoAlertPresenting {
    func showInfoAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

protocol URLOpening {
    func open(_ url: URL)
}

struct SystemURLOpener: URLOpening {
    func open(_ url: URL) {
        NSWorkspace.shared.open(url)
    }
}

