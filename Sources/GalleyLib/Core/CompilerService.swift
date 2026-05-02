import Foundation

protocol Compiling {
    func compileTypst(_ source: String) async throws -> Data
}

class CompilerService: Compiling {
    private let typstURL: URL
    private let parser = OutputParser()

    enum CompilerError: Error, LocalizedError {
        case typstNotFound
        case compilationFailed(CompilationError)

        var errorDescription: String? {
            switch self {
            case .typstNotFound:
                return "Typst compiler not found. Please install it with: brew install typst"
            case .compilationFailed(let error):
                return error.message
            }
        }
    }

    init(typstURL: URL? = nil) throws {
        if let url = typstURL {
            self.typstURL = url
        } else {
            guard let url = Self.findTypst() else {
                throw CompilerError.typstNotFound
            }
            self.typstURL = url
        }
    }

    func compileTypst(_ source: String) async throws -> Data {
        guard !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CompilerError.compilationFailed(
                CompilationError(message: "No content to compile")
            )
        }

        guard let sourceData = source.data(using: .utf8) else {
            throw ProcessError.executionFailed(1, "Invalid source encoding")
        }

        do {
            let output = try await Process.runAsync(
                executableURL: typstURL,
                arguments: ["compile", "-", "-", "--format", "pdf"],
                input: sourceData,
                timeout: 5.0
            )
            return output
        } catch let error as ProcessError {
            if case .executionFailed(_, let stderr) = error {
                let errors = parser.parse(stderr)
                if let firstError = errors.first {
                    throw CompilerError.compilationFailed(firstError)
                }
                throw CompilerError.compilationFailed(
                    CompilationError(message: stderr, line: nil, column: nil)
                )
            }
            throw error
        }
    }

    private static func findTypst() -> URL? {
        let fileManager = FileManager.default
        let paths = [
            "/usr/local/bin/typst",
            "/opt/homebrew/bin/typst",
            "/usr/bin/typst"
        ]

        for path in paths {
            if fileManager.fileExists(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }

        return try? findInPath("typst")
    }

    private static func findInPath(_ executable: String) throws -> URL? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        task.arguments = [executable]

        let pipe = Pipe()
        task.standardOutput = pipe

        try task.run()
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !path.isEmpty else {
            return nil
        }

        return URL(fileURLWithPath: path)
    }
}

class MockCompiler: Compiling {
    var returnValue: Data = Data()
    var shouldThrow: Error?
    var onCompile: ((String) -> Void)?

    func compileTypst(_ source: String) async throws -> Data {
        onCompile?(source)
        if let error = shouldThrow {
            throw error
        }
        return returnValue
    }
}
