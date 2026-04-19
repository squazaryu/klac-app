import Foundation

struct BundledFallbackPackPaths: Equatable {
    let keyDown: [String]
    let keyUp: [String]
    let spaceDown: [String]
    let spaceUp: [String]
    let enterDown: [String]
    let enterUp: [String]
    let backspaceDown: [String]
    let backspaceUp: [String]
}

enum BundledFallbackPackProvider {
    static func kalihBoxWhite() -> BundledFallbackPackPaths {
        BundledFallbackPackPaths(
            keyDown: ["Sounds/kalihboxwhite/kalihboxwhite-press_key1.mp3"],
            keyUp: ["Sounds/kalihboxwhite/kalihboxwhite-release_key.mp3"],
            spaceDown: ["Sounds/kalihboxwhite/kalihboxwhite-press_space.mp3"],
            spaceUp: ["Sounds/kalihboxwhite/kalihboxwhite-release_space.mp3"],
            enterDown: ["Sounds/kalihboxwhite/kalihboxwhite-press_enter.mp3"],
            enterUp: ["Sounds/kalihboxwhite/kalihboxwhite-release_enter.mp3"],
            backspaceDown: ["Sounds/kalihboxwhite/kalihboxwhite-press_back.mp3"],
            backspaceUp: ["Sounds/kalihboxwhite/kalihboxwhite-release_back.mp3"]
        )
    }
}
