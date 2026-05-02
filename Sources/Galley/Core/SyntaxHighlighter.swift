import Foundation

struct SyntaxHighlighter {
    private let keywords = [
        "let", "if", "else", "for", "while", "break", "continue",
        "return", "import", "include", "show", "set", "function",
        "true", "false", "none", "in", "and", "or", "not"
    ]

    private let builtins = [
        "text", "align", "block", "box", "circle", "ellipse",
        "image", "line", "polygon", "rect", "table", "grid",
        "columns", "rows", "page", "pagebreak", "enum", "list",
        "quote", "heading", "strong", "emph", "underline",
        "strikethrough", "superscript", "subscript", "link",
        "label", "ref", "counter", "state", "locate", "measure"
    ]

    func tokenize(_ code: String) -> [Token] {
        var tokens: [Token] = []
        var currentIndex = code.startIndex

        while currentIndex < code.endIndex {
            let char = code[currentIndex]

            if char.isWhitespace {
                currentIndex = code.index(after: currentIndex)
                continue
            }

            if char == "/" && peekAhead(code, currentIndex) == "/" {
                let (endIndex, comment) = scanLineComment(code, currentIndex)
                let range = NSRange(currentIndex..<endIndex, in: code)
                tokens.append(Token(type: .comment, range: range, value: comment))
                currentIndex = endIndex
                continue
            }

            if char == "/" && peekAhead(code, currentIndex) == "*" {
                let (endIndex, comment) = scanBlockComment(code, currentIndex)
                let range = NSRange(currentIndex..<endIndex, in: code)
                tokens.append(Token(type: .comment, range: range, value: comment))
                currentIndex = endIndex
                continue
            }

            if char == "\"" {
                let (endIndex, string) = scanString(code, currentIndex)
                let range = NSRange(currentIndex..<endIndex, in: code)
                tokens.append(Token(type: .string, range: range, value: string))
                currentIndex = endIndex
                continue
            }

            if char == "#" {
                let nextIndex = code.index(after: currentIndex)
                if nextIndex < code.endIndex && (code[nextIndex].isLetter || code[nextIndex] == "_") {
                    let (endIndex, identifier) = scanIdentifier(code, nextIndex)
                    let fullValue = "#" + identifier
                    let range = NSRange(currentIndex..<endIndex, in: code)

                    if keywords.contains(identifier) {
                        tokens.append(Token(type: .keyword, range: range, value: fullValue))
                    } else if builtins.contains(identifier) {
                        tokens.append(Token(type: .function, range: range, value: fullValue))
                    } else {
                        tokens.append(Token(type: .markup, range: range, value: fullValue))
                    }

                    currentIndex = endIndex
                    continue
                } else {
                    let range = NSRange(currentIndex..<code.index(after: currentIndex), in: code)
                    tokens.append(Token(type: .punctuation, range: range, value: "#"))
                    currentIndex = code.index(after: currentIndex)
                    continue
                }
            }

            if char.isLetter || char == "_" {
                let (endIndex, identifier) = scanIdentifier(code, currentIndex)
                let range = NSRange(currentIndex..<endIndex, in: code)

                if keywords.contains(identifier) {
                    tokens.append(Token(type: .keyword, range: range, value: identifier))
                } else if builtins.contains(identifier) {
                    tokens.append(Token(type: .function, range: range, value: identifier))
                } else {
                    tokens.append(Token(type: .variable, range: range, value: identifier))
                }

                currentIndex = endIndex
                continue
            }

            if char.isNumber {
                let (endIndex, number) = scanNumber(code, currentIndex)
                let range = NSRange(currentIndex..<endIndex, in: code)
                tokens.append(Token(type: .number, range: range, value: number))
                currentIndex = endIndex
                continue
            }

            if "(){}[],;:=+-*/<>!&|.".contains(char) {
                let range = NSRange(currentIndex..<code.index(after: currentIndex), in: code)
                tokens.append(Token(type: .punctuation, range: range, value: String(char)))
                currentIndex = code.index(after: currentIndex)
                continue
            }

            currentIndex = code.index(after: currentIndex)
        }

        return tokens
    }

    private func scanLineComment(_ code: String, _ start: String.Index) -> (String.Index, String) {
        let end = code.firstIndex(of: "\n") ?? code.endIndex
        let value = String(code[start..<end])
        return (end, value)
    }

    private func scanBlockComment(_ code: String, _ start: String.Index) -> (String.Index, String) {
        var current = code.index(start, offsetBy: 2)
        while current < code.endIndex {
            if code[current] == "*" && code.index(after: current) < code.endIndex && code[code.index(after: current)] == "/" {
                let end = code.index(current, offsetBy: 2)
                return (end, String(code[start..<end]))
            }
            current = code.index(after: current)
        }
        return (code.endIndex, String(code[start...]))
    }

    private func scanString(_ code: String, _ start: String.Index) -> (String.Index, String) {
        var current = code.index(after: start)
        while current < code.endIndex {
            if code[current] == "\"" && (current == start || code[code.index(before: current)] != "\\") {
                let end = code.index(after: current)
                return (end, String(code[start..<end]))
            }
            current = code.index(after: current)
        }
        return (code.endIndex, String(code[start...]))
    }

    private func scanIdentifier(_ code: String, _ start: String.Index) -> (String.Index, String) {
        var current = start
        while current < code.endIndex && (code[current].isLetter || code[current].isNumber || code[current] == "_") {
            current = code.index(after: current)
        }
        return (current, String(code[start..<current]))
    }

    private func scanNumber(_ code: String, _ start: String.Index) -> (String.Index, String) {
        var current = start
        var hasDecimal = false
        while current < code.endIndex {
            if code[current].isNumber {
                current = code.index(after: current)
            } else if code[current] == "." && !hasDecimal {
                hasDecimal = true
                current = code.index(after: current)
            } else {
                break
            }
        }
        return (current, String(code[start..<current]))
    }

    private func peekAhead(_ code: String, _ index: String.Index) -> Character? {
        let nextIndex = code.index(after: index)
        return nextIndex < code.endIndex ? code[nextIndex] : nil
    }
}
