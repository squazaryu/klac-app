import Foundation

final class PersistentDebugLogService {
    private enum DefaultsKey {
        static let sessionRunning = "diagnostics.sessionRunning"
    }

    private let fileManager: FileManager
    private let defaults: UserDefaults
    private let queue = DispatchQueue(label: "com.klac.persistent-debug-log", qos: .utility)
    private let maxLogBytes: Int
    private let maxArchives: Int
    private let logFileURL: URL

    init(
        fileManager: FileManager = .default,
        defaults: UserDefaults = .standard,
        maxLogBytes: Int = 1_500_000,
        maxArchives: Int = 3
    ) {
        self.fileManager = fileManager
        self.defaults = defaults
        self.maxLogBytes = max(200_000, maxLogBytes)
        self.maxArchives = max(1, maxArchives)
        let logsRoot = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/Klac", isDirectory: true)
        logFileURL = logsRoot.appendingPathComponent("runtime.log")
        ensureDirectoryExists()
    }

    func beginSession(appVersion: String, buildNumber: Int) -> Bool {
        let hadUngracefulExit = defaults.bool(forKey: DefaultsKey.sessionRunning)
        defaults.set(true, forKey: DefaultsKey.sessionRunning)
        appendRaw("=== Session started: v\(appVersion) (\(buildNumber)) ===")
        if hadUngracefulExit {
            appendRaw("WARNING: previous session finished unexpectedly (possible crash/force-kill).")
        }
        return hadUngracefulExit
    }

    func append(_ line: String) {
        appendRaw(line)
    }

    func markGracefulShutdown() {
        appendRaw("=== Session finished gracefully ===")
        defaults.set(false, forKey: DefaultsKey.sessionRunning)
    }

    func clearLogFile() {
        queue.sync {
            try? "".data(using: .utf8)?.write(to: logFileURL, options: .atomic)
        }
    }

    private func ensureDirectoryExists() {
        let directory = logFileURL.deletingLastPathComponent()
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private func appendRaw(_ message: String) {
        queue.async { [weak self] in
            guard let self else { return }
            self.rotateIfNeeded()
            let line = message.hasSuffix("\n") ? message : (message + "\n")
            guard let data = line.data(using: .utf8) else { return }
            if self.fileManager.fileExists(atPath: self.logFileURL.path) {
                if let handle = try? FileHandle(forWritingTo: self.logFileURL) {
                    defer { try? handle.close() }
                    do {
                        try handle.seekToEnd()
                        try handle.write(contentsOf: data)
                    } catch {
                        // Best-effort logger: swallow IO errors.
                    }
                }
            } else {
                try? data.write(to: self.logFileURL, options: .atomic)
            }
        }
    }

    private func rotateIfNeeded() {
        guard let attrs = try? fileManager.attributesOfItem(atPath: logFileURL.path),
              let fileSize = attrs[.size] as? NSNumber,
              fileSize.intValue >= maxLogBytes
        else {
            return
        }

        for index in stride(from: maxArchives, through: 1, by: -1) {
            let source = archiveURL(index: index)
            let target = archiveURL(index: index + 1)
            if fileManager.fileExists(atPath: target.path) {
                try? fileManager.removeItem(at: target)
            }
            if fileManager.fileExists(atPath: source.path) {
                try? fileManager.moveItem(at: source, to: target)
            }
        }

        let firstArchive = archiveURL(index: 1)
        if fileManager.fileExists(atPath: firstArchive.path) {
            try? fileManager.removeItem(at: firstArchive)
        }
        if fileManager.fileExists(atPath: logFileURL.path) {
            try? fileManager.moveItem(at: logFileURL, to: firstArchive)
        }
    }

    private func archiveURL(index: Int) -> URL {
        let baseName = logFileURL.deletingPathExtension().lastPathComponent
        return logFileURL
            .deletingLastPathComponent()
            .appendingPathComponent("\(baseName).\(index).log")
    }
}
