import Foundation

struct OutputParser {
    func parse(_ stderr: String) -> [CompilationError] {
        let lines = stderr.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var errors: [CompilationError] = []
        var currentMessage: String?
        var currentLine: Int?
        var currentColumn: Int?
        var currentContext: String?

        var i = 0
        while i < lines.count {
            let line = lines[i]

            if line.hasPrefix("error:") {
                if let previousError = createError(
                    message: currentMessage,
                    line: currentLine,
                    column: currentColumn,
                    context: currentContext
                ) {
                    errors.append(previousError)
                }

                currentMessage = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                currentLine = nil
                currentColumn = nil
                currentContext = nil
            } else if line.contains("┌─") {
                let locationParts = extractLocation(from: line)
                currentLine = locationParts.line
                currentColumn = locationParts.column
            } else if line.contains("│") && !line.contains("┌") {
                let content = line.split(separator: "│", maxSplits: 1).last
                    .map(String.init)?
                    .trimmingCharacters(in: .whitespaces) ?? ""
                if !content.isEmpty && !content.hasPrefix("-") {
                    currentContext = content
                }
            }

            i += 1
        }

        if let lastError = createError(
            message: currentMessage,
            line: currentLine,
            column: currentColumn,
            context: currentContext
        ) {
            errors.append(lastError)
        }

        return errors
    }

    private func extractLocation(from line: String) -> (line: Int?, column: Int?) {
        let pattern = #"(\d+):(\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return (nil, nil)
        }

        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        guard let match = regex.firstMatch(in: line, range: range) else {
            return (nil, nil)
        }

        var lineNumber: Int?
        var columnNumber: Int?

        if match.numberOfRanges > 1 {
            if let matchRange = Range(match.range(at: 1), in: line) {
                lineNumber = Int(String(line[matchRange]))
            }
        }

        if match.numberOfRanges > 2 {
            if let matchRange = Range(match.range(at: 2), in: line) {
                columnNumber = Int(String(line[matchRange]))
            }
        }

        return (lineNumber, columnNumber)
    }

    private func createError(
        message: String?,
        line: Int?,
        column: Int?,
        context: String?
    ) -> CompilationError? {
        guard let message = message, !message.isEmpty else { return nil }
        return CompilationError(
            message: message,
            line: line,
            column: column,
            context: context
        )
    }
}
