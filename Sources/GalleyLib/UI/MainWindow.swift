import SwiftUI
import PDFKit

struct PreviewPane: View {
    @ObservedObject var state: EditorState

    var body: some View {
        VStack(spacing: 0) {
            if let pdfData = state.pdfData {
                PDFPreviewView(pdfData: pdfData)
            } else if state.isCompiling {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Compiling...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.controlBackgroundColor))
            } else {
                Text("Ready")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.controlBackgroundColor))
            }

            if let error = state.compilationError {
                Divider()
                ErrorPanelView(error: error)
                    .frame(height: 100)
            }
        }
    }
}
