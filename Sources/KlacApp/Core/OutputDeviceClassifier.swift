import Foundation

enum OutputDeviceClassifier {
    static func looksLikeHeadphones(_ name: String) -> Bool {
        let normalized = name.lowercased()
        let headphoneTokens = [
            "headphone", "headphones", "airpods", "earbuds", "buds",
            "nothing", "beats", "sony", "bose", "jbl", "wh-", "wf-",
            "bt", "bluetooth", "науш"
        ]
        if headphoneTokens.contains(where: { normalized.contains($0) }) {
            return true
        }
        let speakerTokens = ["speaker", "speakers", "динам", "built-in", "macbook"]
        if speakerTokens.contains(where: { normalized.contains($0) }) {
            return false
        }
        return false
    }
}
