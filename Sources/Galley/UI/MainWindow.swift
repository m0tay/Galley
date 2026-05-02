import SwiftUI
import PDFKit

struct MainWindow: View {
    @StateObject private var editorState: EditorState

    init(compiler: any Compiling = try! CompilerService()) {
        _editorState = StateObject(wrappedValue: EditorState(compiler: compiler))
    }

    var body: some View {
        HSplitView {
            EditorView(state: editorState)
                .frame(minWidth: 300)

            VStack(spacing: 0) {
                if let pdfData = editorState.pdfData {
                    PDFPreviewView(pdfData: pdfData)
                } else if editorState.isCompiling {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Compiling...")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.controlBackgroundColor))
                } else {
                    VStack {
                        Text("Ready")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.controlBackgroundColor))
                }

                if let error = editorState.compilationError {
                    Divider()
                    ErrorPanelView(error: error)
                        .frame(height: 100)
                }
            }
            .frame(minWidth: 300)
        }
        .onDisappear {
            editorState.saveDocument()
        }
    }
}

#if DEBUG
struct MainWindow_Previews: PreviewProvider {
    static var previews: some View {
        MainWindow(compiler: MockCompiler())
    }
}
#endif
