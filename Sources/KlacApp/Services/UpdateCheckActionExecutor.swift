import Foundation

enum UpdateCheckActionExecutor {
    static func execute(
        _ action: UpdateCheckUIAction?,
        alertPresenter: InfoAlertPresenting,
        urlOpener: URLOpening
    ) {
        guard let action else { return }
        switch action {
        case let .showInfoAlert(title, message):
            alertPresenter.showInfoAlert(title: title, message: message)
        case let .openRelease(url):
            urlOpener.open(url)
        }
    }
}
