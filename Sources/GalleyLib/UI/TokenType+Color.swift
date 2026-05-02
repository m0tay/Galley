import AppKit

extension TokenType {
    var highlightColor: NSColor {
        switch self {
        case .keyword:    return .systemPurple
        case .function:   return .systemBlue
        case .string:     return .systemRed
        case .number:     return .systemGreen
        case .comment:    return .systemGray
        case .markup:     return .systemOrange
        case .variable, .punctuation, .unknown: return .labelColor
        }
    }
}
