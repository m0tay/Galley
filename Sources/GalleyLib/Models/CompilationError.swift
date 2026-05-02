import Foundation

struct CompilationError: Identifiable, Equatable {
    let id: UUID
    let message: String
    let line: Int?
    let column: Int?
    let context: String?

    init(
        message: String,
        line: Int? = nil,
        column: Int? = nil,
        context: String? = nil,
        id: UUID = UUID()
    ) {
        self.message = message
        self.line = line
        self.column = column
        self.context = context
        self.id = id
    }

    static func == (lhs: CompilationError, rhs: CompilationError) -> Bool {
        lhs.message == rhs.message &&
            lhs.line == rhs.line &&
            lhs.column == rhs.column &&
            lhs.context == rhs.context
    }
}
