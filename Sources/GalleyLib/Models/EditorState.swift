import Foundation
import Combine

class EditorState: ObservableObject {
    @Published var editorText: String = ""
    @Published var pdfData: Data?
    @Published var compilationError: CompilationError?
    @Published var isCompiling: Bool = false
    @Published var document: Document

    private var cancellables = Set<AnyCancellable>()
    private let compiler: any Compiling
    private var compilationTask: Task<Void, Never>?

    init(compiler: any Compiling = try! CompilerService(), document: Document = Document()) {
        self.compiler = compiler
        self.document = document
        self.editorText = document.content

        setupBindings()
    }

    private func setupBindings() {
        $editorText
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] text in
                self?.compile(text)
            }
            .store(in: &cancellables)
    }

    private func compile(_ source: String) {
        compilationTask?.cancel()

        if source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            compilationError = nil
            isCompiling = false
            return
        }

        compilationTask = Task {
            await MainActor.run { self.isCompiling = true }

            do {
                let pdf = try await compiler.compileTypst(source)
                await MainActor.run {
                    self.pdfData = pdf
                    self.compilationError = nil
                    self.isCompiling = false
                }
            } catch let error as CompilerService.CompilerError {
                let compilationError: CompilationError
                switch error {
                case .compilationFailed(let err):
                    compilationError = err
                case .typstNotFound:
                    compilationError = CompilationError(
                        message: error.errorDescription ?? "Typst not found"
                    )
                }
                await MainActor.run {
                    self.compilationError = compilationError
                    self.pdfData = nil
                    self.isCompiling = false
                }
            } catch {
                await MainActor.run {
                    self.compilationError = CompilationError(message: error.localizedDescription)
                    self.pdfData = nil
                    self.isCompiling = false
                }
            }
        }
    }

    func saveDocument() {
        document.content = editorText
        document.lastCompiled = Date()
    }

    func resetContent() {
        editorText = ""
        pdfData = nil
        compilationError = nil
    }
}
