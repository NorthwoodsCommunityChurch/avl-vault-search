import SwiftUI

struct SearchResult: Codable, Identifiable {
    let fileId: String
    let path: String
    let filename: String
    let type: String
    let description: String?
    let tags: String?
    let duration: Double?
    let width: Int?
    let height: Int?

    var id: String { path }

    enum CodingKeys: String, CodingKey {
        case fileId = "id"
        case path, filename, type, description, tags, duration, width, height
    }

    var thumbnailURL: URL? {
        var components = URLComponents(string: "http://10.10.11.173:8081/thumbnail")!
        components.queryItems = [URLQueryItem(name: "id", value: fileId)]
        return components.url
    }

    var typeLabel: String {
        type.uppercased()
    }

    var typeIcon: String {
        switch type {
        case "video": return "film"
        case "image": return "photo"
        case "audio": return "waveform"
        default: return "doc"
        }
    }

    var typeColor: Color {
        switch type {
        case "video": return .blue
        case "image": return .green
        case "audio": return .orange
        default: return .gray
        }
    }

    var displayDescription: String {
        description ?? "No description"
    }

    var durationFormatted: String? {
        guard let duration = duration, duration > 0 else { return nil }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var resolutionFormatted: String? {
        guard let width = width, let height = height else { return nil }
        return "\(width)x\(height)"
    }
}
