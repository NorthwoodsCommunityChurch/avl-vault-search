import Foundation

struct FaceCluster: Codable, Identifiable {
    let clusterId: Int
    let personId: String?
    let personName: String?
    let faceCount: Int
    let sampleFaces: [SampleFace]

    var id: Int { clusterId }

    var isNamed: Bool { personName != nil && !personName!.isEmpty }

    var firstThumbnailURL: URL? {
        guard let first = sampleFaces.first else { return nil }
        return URL(string: "http://10.10.11.157:8081\(first.thumbnail)")
    }

    var allThumbnailURLs: [URL] {
        sampleFaces.compactMap { URL(string: "http://10.10.11.157:8081\($0.thumbnail)") }
    }

    enum CodingKeys: String, CodingKey {
        case clusterId = "cluster_id"
        case personId = "person_id"
        case personName = "person_name"
        case faceCount = "face_count"
        case sampleFaces = "sample_faces"
    }
}

struct SampleFace: Codable {
    let faceId: String
    let thumbnail: String

    enum CodingKeys: String, CodingKey {
        case faceId = "face_id"
        case thumbnail
    }
}

struct FaceStatus: Codable {
    let totalFaces: Int
    let clusteredFaces: Int
    let namedFaces: Int
    let unnamedClusters: Int
    let namedPersons: Int
    let filesWithFaces: Int
    let filesWithoutFaceScan: Int
    let faceRecognitionAvailable: Bool

    enum CodingKeys: String, CodingKey {
        case totalFaces = "total_faces"
        case clusteredFaces = "clustered_faces"
        case namedFaces = "named_faces"
        case unnamedClusters = "unnamed_clusters"
        case namedPersons = "named_persons"
        case filesWithFaces = "files_with_faces"
        case filesWithoutFaceScan = "files_without_face_scan"
        case faceRecognitionAvailable = "face_recognition_available"
    }
}

struct ClustersResponse: Codable {
    let clusters: [FaceCluster]
}

struct DetectProgress: Codable {
    let running: Bool
    let processed: Int
    let total: Int
    let facesFound: Int
    let currentFile: String

    enum CodingKeys: String, CodingKey {
        case running, processed, total
        case facesFound = "faces_found"
        case currentFile = "current_file"
    }
}
