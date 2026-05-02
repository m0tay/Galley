import Foundation

enum ProcessError: Error, LocalizedError {
    case executableNotFound(String)
    case executionFailed(Int32, String)
    case timeout

    var errorDescription: String? {
        switch self {
        case .executableNotFound(let path):
            return "Executable not found: \(path)"
        case .executionFailed(let code, let stderr):
            return "Process exited with code \(code): \(stderr)"
        case .timeout:
            return "Process execution timed out"
        }
    }
}

extension Process {
    static func runAsync(
        executableURL: URL,
        arguments: [String],
        input: Data,
        timeout: TimeInterval = 5.0
    ) async throws -> Data {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments

        let inputPipe = Pipe()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()

        let writeTask = Task {
            do {
                try inputPipe.fileHandleForWriting.write(contentsOf: input)
                try inputPipe.fileHandleForWriting.close()
            } catch {
                try? inputPipe.fileHandleForWriting.close()
            }
        }

        _ = await writeTask.result

        let readTask = Task {
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            return (outputData, errorData)
        }

        let startTime = Date()
        while !process.isRunning || Date().timeIntervalSince(startTime) < timeout {
            if !process.isRunning {
                break
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        if process.isRunning {
            process.terminate()
            throw ProcessError.timeout
        }

        let (output, errorOutput) = await readTask.value

        if process.terminationStatus != 0 {
            let errorString = String(data: errorOutput, encoding: .utf8) ?? "Unknown error"
            throw ProcessError.executionFailed(process.terminationStatus, errorString)
        }

        return output
    }
}
