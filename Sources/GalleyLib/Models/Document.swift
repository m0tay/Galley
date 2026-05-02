import Foundation

struct Document: Codable, Identifiable {
    let id: UUID
    var content: String
    var lastCompiled: Date
    var fileURL: URL?

    init(
        id: UUID = UUID(),
        content: String = "",
        lastCompiled: Date = Date(),
        fileURL: URL? = nil
    ) {
        self.id = id
        self.content = content
        self.lastCompiled = lastCompiled
        self.fileURL = fileURL
    }

    enum CodingKeys: String, CodingKey {
        case id
        case content
        case lastCompiled = "last_compiled"
        case fileURL = "file_url"
    }
}
