import AppKit
import AVFoundation
import ApplicationServices
import Foundation

enum KeyEventType {
    case down
    case up
}

final class GlobalKeyEventTap {
    var onEvent: ((KeyEventType, Int, Bool) -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var globalMonitor: Any?
    private var firstEventLogged = false

    func start() -> Bool {
        if eventTap != nil || globalMonitor != nil { return true }
        firstEventLogged = false

        let mask = (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            _ = proxy
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let instance = Unmanaged<GlobalKeyEventTap>.fromOpaque(refcon).takeUnretainedValue()

            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                if let tap = instance.eventTap {
                    CGEvent.tapEnable(tap: tap, enable: true)
                }
                return Unmanaged.passUnretained(event)
            }

            let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
            let isAutorepeat = event.getIntegerValueField(.keyboardEventAutorepeat) == 1

            if type == .keyDown || type == .keyUp {
                if !instance.firstEventLogged {
                    instance.firstEventLogged = true
                    NSLog("Keyboard events are flowing via CGEvent tap (first event keyCode=\(keyCode), type=\(type.rawValue))")
                }
                instance.onEvent?(type == .keyDown ? .down : .up, keyCode, isAutorepeat)
                return Unmanaged.passUnretained(event)
            }

            if type == .flagsChanged {
                guard let modifierEvent = instance.modifierEventType(for: keyCode, flags: event.flags) else {
                    return Unmanaged.passUnretained(event)
                }
                instance.onEvent?(modifierEvent, keyCode, false)
            }

            return Unmanaged.passUnretained(event)
        }

        let ref = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: ref
        ) else {
            NSLog("CGEvent tap creation failed. Trying NSEvent global monitor fallback.")
            return startGlobalMonitorFallback()
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFMachPortSetInvalidationCallBack(tap) { _, _ in }

        eventTap = tap
        runLoopSource = source

        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        NSLog("Using CGEvent tap keyboard capture")
        return true
    }

    func stop() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let tap = eventTap {
            CFMachPortInvalidate(tap)
        }
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
        }
        runLoopSource = nil
        eventTap = nil
        globalMonitor = nil
    }

    private func startGlobalMonitorFallback() -> Bool {
        let monitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.keyDown, .keyUp, .flagsChanged]
        ) { [weak self] event in
            guard let self else { return }
            switch event.type {
            case .keyDown:
                if !self.firstEventLogged {
                    self.firstEventLogged = true
                    NSLog("Keyboard events are flowing via NSEvent global monitor (first keyDown keyCode=\(event.keyCode))")
                }
                DispatchQueue.main.async {
                    self.onEvent?(.down, Int(event.keyCode), event.isARepeat)
                }
            case .keyUp:
                DispatchQueue.main.async {
                    self.onEvent?(.up, Int(event.keyCode), false)
                }
            case .flagsChanged:
                let flags = CGEventFlags(rawValue: UInt64(event.modifierFlags.rawValue))
                guard let modifierEvent = self.modifierEventType(for: Int(event.keyCode), flags: flags) else {
                    return
                }
                DispatchQueue.main.async {
                    self.onEvent?(modifierEvent, Int(event.keyCode), false)
                }
            default:
                return
            }
        }

        guard let monitor else {
            NSLog("Global keyboard monitor fallback failed to start")
            return false
        }
        globalMonitor = monitor
        NSLog("Using NSEvent global keyboard monitor fallback")
        return true
    }

    private func modifierEventType(for keyCode: Int, flags: CGEventFlags) -> KeyEventType? {
        let isDown: Bool
        switch keyCode {
        case 55, 54:
            isDown = flags.contains(.maskCommand)
        case 58, 61:
            isDown = flags.contains(.maskAlternate)
        case 59, 62:
            isDown = flags.contains(.maskControl)
        case 56, 60:
            isDown = flags.contains(.maskShift)
        case 57:
            isDown = flags.contains(.maskAlphaShift)
        default:
            return nil
        }
        return isDown ? .down : .up
    }
}

