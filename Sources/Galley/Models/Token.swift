import Foundation

enum TokenType {
    case keyword
    case function
    case variable
    case string
    case number
    case comment
    case punctuation
    case markup
    case unknown
}

struct Token {
    let type: TokenType
    let range: NSRange
    let value: String

    init(type: TokenType, range: NSRange, value: String) {
        self.type = type
        self.range = range
        self.value = value
    }
}
