import Foundation

enum UpdateCheckUIAction: Equatable {
    case showInfoAlert(title: String, message: String)
    case openRelease(url: URL)
}

struct UpdateCheckPresentation: Equatable {
    let statusText: String
    let debugMessage: String
    let action: UpdateCheckUIAction?
}

enum UpdateCheckPresentationCoordinator {
    static func presentable(result: UpdateCheckResult, currentVersion: String) -> UpdateCheckPresentation {
        switch result {
        case .upToDate:
            return UpdateCheckPresentation(
                statusText: "У вас актуальная версия (\(currentVersion)).",
                debugMessage: "Update check: already up to date (\(currentVersion))",
                action: .showInfoAlert(
                    title: "Обновлений нет",
                    message: "Текущая версия \(currentVersion) уже актуальна."
                )
            )
        case .invalidReleaseLink(let latestVersion):
            return UpdateCheckPresentation(
                statusText: "Некорректная ссылка релиза.",
                debugMessage: "Update check: invalid release URL for \(latestVersion)",
                action: .showInfoAlert(
                    title: "Обновление недоступно",
                    message: "Новая версия \(latestVersion) найдена, но ссылка на релиз некорректна."
                )
            )
        case .updateAvailable(let latestVersion, let releaseURL):
            return UpdateCheckPresentation(
                statusText: "Найдена версия \(latestVersion). Открываю релиз...",
                debugMessage: "Update check: newer version found \(latestVersion), opening release page",
                action: .openRelease(url: releaseURL)
            )
        }
    }

    static func presentable(error: Error) -> UpdateCheckPresentation {
        let message = error.localizedDescription
        return UpdateCheckPresentation(
            statusText: "Ошибка обновления: \(message)",
            debugMessage: "Update check failed: \(message)",
            action: .showInfoAlert(
                title: "Ошибка обновления",
                message: message
            )
        )
    }
}

