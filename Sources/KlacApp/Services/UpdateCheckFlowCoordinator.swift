import Foundation

protocol UpdateCheckFlowCoordinating {
    func run(currentVersion: String, currentBuild: Int) async -> UpdateCheckPresentation
}

struct UpdateCheckFlowCoordinator: UpdateCheckFlowCoordinating {
    private let updateChecker: any UpdateChecking

    init(updateChecker: any UpdateChecking) {
        self.updateChecker = updateChecker
    }

    func run(currentVersion: String, currentBuild: Int) async -> UpdateCheckPresentation {
        do {
            let result = try await updateChecker.check(
                currentVersion: currentVersion,
                currentBuild: currentBuild
            )
            return UpdateCheckPresentationCoordinator.presentable(
                result: result,
                currentVersion: currentVersion
            )
        } catch {
            return UpdateCheckPresentationCoordinator.presentable(error: error)
        }
    }
}

