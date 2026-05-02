import SwiftUI

struct ErrorPanelView: View {
    let error: CompilationError

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.headline)

                VStack(alignment: .leading, spacing: 4) {
                    if let line = error.line, let column = error.column {
                        Text("Line \(line), Column \(column)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text(error.message)
                        .font(.body)
                        .lineLimit(2)
                }

                Spacer()
            }

            if let context = error.context {
                Divider()
                Text(context)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(8)
        .background(Color(.controlBackgroundColor))
    }
}

