import Foundation

struct UpdateCheckRuntimeDependencies {
    let setInProgress: (Bool) -> Void
    let setStatusText: (String) -> Void
    let recordDebug: (String) -> Void
    let runFlow: (String, Int) async -> UpdateCheckPresentation
    let executeAction: (UpdateCheckUIAction?) -> Void
}

enum UpdateCheckRuntimeCoordinator {
    @MainActor
    static func runIfNeeded(
        isAlreadyInProgress: Bool,
        currentVersion: String,
        currentBuild: Int,
        dependencies: UpdateCheckRuntimeDependencies
    ) async {
        guard !isAlreadyInProgress else { return }

        dependencies.setInProgress(true)
        dependencies.setStatusText("Проверка...")
        dependencies.recordDebug("Update check started")
        defer { dependencies.setInProgress(false) }

        let presentation = await dependencies.runFlow(currentVersion, currentBuild)
        dependencies.setStatusText(presentation.statusText)
        dependencies.recordDebug(presentation.debugMessage)
        dependencies.executeAction(presentation.action)
    }
}
