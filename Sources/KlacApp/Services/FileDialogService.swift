import AppKit
import Foundation
import UniformTypeIdentifiers

protocol FileDialogPresenting {
    func pickProfileExportURL() -> URL?
    func pickProfileImportURL() -> URL?
    func pickDebugLogExportURL(defaultFileName: String) -> URL?
}

struct SystemFileDialogService: FileDialogPresenting {
    func pickProfileExportURL() -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "klac-profile.json"
        panel.title = "Экспорт настроек профиля"
        panel.message = "Сохранить текущие настройки звука"
        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }

    func pickProfileImportURL() -> URL? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Импорт настроек профиля"
        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }

    func pickDebugLogExportURL(defaultFileName: String) -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = defaultFileName
        panel.title = "Экспорт debug-логов"
        panel.message = "Сохранить диагностический лог приложения"
        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }
}

protocol FileReadWriting {
    func write(_ data: Data, to url: URL) throws
    func read(from url: URL) throws -> Data
}

struct FileSystemReadWriter: FileReadWriting {
    func write(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: .atomic)
    }

    func read(from url: URL) throws -> Data {
        try Data(contentsOf: url)
    }
}

