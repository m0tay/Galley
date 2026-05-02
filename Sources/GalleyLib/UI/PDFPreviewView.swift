import SwiftUI
import PDFKit

struct PDFPreviewView: View {
    let pdfData: Data

    var body: some View {
        ZStack {
            PDFViewControllerRepresentable(data: pdfData)

            VStack {
                HStack {
                    Text("PDF Preview")
                        .font(.headline)
                    Spacer()
                }
                .padding(8)
                .background(Color(.controlBackgroundColor))

                Spacer()
            }
        }
    }
}

struct PDFViewControllerRepresentable: NSViewRepresentable {
    let data: Data

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(data: data)
        pdfView.autoScales = true
        return pdfView
    }

    func updateNSView(_ nsView: PDFView, context: Context) {
        nsView.document = PDFDocument(data: data)
    }
}

