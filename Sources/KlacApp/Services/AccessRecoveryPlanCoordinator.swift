import Foundation

struct AccessRecoveryPlan {
    let tccServicesToReset: [String]
    let postResetHint: String
    let wizardHint: String
    let restartFailureHint: String
}

enum AccessRecoveryPlanCoordinator {
    static func makePlan() -> AccessRecoveryPlan {
        AccessRecoveryPlan(
            tccServicesToReset: ["Accessibility", "ListenEvent"],
            postResetHint: "Доступы сброшены. Включи Klac в Универсальном доступе и Мониторинге ввода, затем перезапусти приложение.",
            wizardHint: "Открыл Универсальный доступ и Мониторинг ввода. После перезапуска включи Klac в обоих списках.",
            restartFailureHint: "Не удалось автоматом перезапустить dev-сборку. Закрой приложение и запусти снова через swift run."
        )
    }
}
