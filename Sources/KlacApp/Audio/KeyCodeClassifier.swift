import Foundation

enum KeyCodeClassifier {
    static func resolveKeyGroup(for keyCode: Int) -> KeyGroup {
        switch keyCode {
        case 49:
            return .space
        case 36, 76:
            return .enter
        case 51, 117:
            return .delete
        case 53, 122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111, 105, 107, 113, 106, 64, 79, 80, 90:
            return .function
        case 123, 124, 125, 126:
            return .arrow
        case 54, 55, 56, 57, 58, 59, 60, 61, 62:
            return .modifier
        default:
            return .alpha
        }
    }
}

