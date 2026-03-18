import SwiftUI

struct MatchedKeyframe: Codable {
    let timestamp: Double
    let description: String
}

struct MatchedSegment: Codable {
    let start: Double
    let end: Double
    let text: String
}

struct MatchedFace: Codable {
    let timestamp: Double
    let name: String
}

struct SearchResult: Codable, Identifiable {
    let fileId: String
    let path: String
    let filename: String
    let type: String?
    let description: String?
    let tags: String?
    let duration: Double?
    let width: Int?
    let height: Int?
    let matchedKeyframes: [MatchedKeyframe]
    let matchedSegments: [MatchedSegment]
    let matchedFaces: [MatchedFace]
    let keyframeCount: Int

    var id: String { path }

    enum CodingKeys: String, CodingKey {
        case fileId = "id"
        case path, filename, type, description, tags, duration, width, height
        case matchedKeyframes = "matched_keyframes"
        case matchedSegments = "matched_segments"
        case matchedFaces = "matched_faces"
        case keyframeCount = "keyframe_count"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fileId = try container.decode(String.self, forKey: .fileId)
        path = try container.decode(String.self, forKey: .path)
        filename = try container.decode(String.self, forKey: .filename)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        tags = try container.decodeIfPresent(String.self, forKey: .tags)
        duration = try container.decodeIfPresent(Double.self, forKey: .duration)
        width = try container.decodeIfPresent(Int.self, forKey: .width)
        height = try container.decodeIfPresent(Int.self, forKey: .height)
        matchedKeyframes = try container.decodeIfPresent([MatchedKeyframe].self, forKey: .matchedKeyframes) ?? []
        matchedSegments = try container.decodeIfPresent([MatchedSegment].self, forKey: .matchedSegments) ?? []
        matchedFaces = try container.decodeIfPresent([MatchedFace].self, forKey: .matchedFaces) ?? []
        keyframeCount = try container.decodeIfPresent(Int.self, forKey: .keyframeCount) ?? 0
    }

    static func formatTimestamp(_ t: Double) -> String {
        let minutes = Int(t) / 60
        let seconds = Int(t) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func keyframeURL(index: Int) -> URL? {
        var components = URLComponents(string: "http://10.10.11.157:8081/thumbnail")!
        components.queryItems = [
            URLQueryItem(name: "id", value: fileId),
            URLQueryItem(name: "keyframe", value: String(index))
        ]
        return components.url
    }

    var thumbnailURL: URL? {
        var components = URLComponents(string: "http://10.10.11.157:8081/thumbnail")!
        components.queryItems = [URLQueryItem(name: "id", value: fileId)]
        return components.url
    }

    var typeLabel: String {
        (type ?? "other").uppercased()
    }

    var typeIcon: String {
        switch type ?? "" {
        case "video": return "film"
        case "image": return "photo"
        case "audio": return "waveform"
        default: return "doc"
        }
    }

    var typeColor: Color {
        switch type ?? "" {
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

    var fileType: String { type ?? "other" }

    var fileInfo: String {
        var parts: [String] = [typeLabel]
        if let res = resolutionFormatted { parts.append(res) }
        if let dur = durationFormatted { parts.append(dur) }
        return parts.joined(separator: " · ")
    }
}
