import Foundation

struct SearchResponse: Codable {
    let query: String
    let count: Int
    let results: [SearchResult]
}

struct SearchResult: Codable, Identifiable {
    let path: String
    let filename: String
    let fileType: String
    let aiDescription: String?
    let tags: String?
    let durationSeconds: Double?
    let width: Int?
    let height: Int?

    var id: String { path }

    enum CodingKeys: String, CodingKey {
        case path, filename, tags, width, height
        case fileType = "file_type"
        case aiDescription = "ai_description"
        case durationSeconds = "duration_seconds"
    }

    var displayDescription: String {
        aiDescription ?? "No description"
    }

    var fileInfo: String {
        var parts: [String] = []

        if let width = width, let height = height {
            parts.append("\(width)x\(height)")
        }

        if let duration = durationSeconds {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            parts.append(String(format: "%d:%02d", minutes, seconds))
        }

        parts.append(fileType.uppercased())

        return parts.joined(separator: " • ")
    }
}

struct IndexStatus: Codable {
    let totalFiles: Int
    let indexedFiles: Int
    let pendingFiles: Int
    let errorFiles: Int

    enum CodingKeys: String, CodingKey {
        case totalFiles = "total_files"
        case indexedFiles = "indexed_files"
        case pendingFiles = "pending_files"
        case errorFiles = "error_files"
    }
}
