import Foundation

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
