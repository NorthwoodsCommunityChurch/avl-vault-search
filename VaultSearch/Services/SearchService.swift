import Foundation

actor SearchService {
    private let baseURL = "http://10.10.11.157:8081"

    func search(query: String, limit: Int = 50) async throws -> [SearchResult] {
        var components = URLComponents(string: "\(baseURL)/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        guard let url = components.url else {
            throw SearchError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SearchError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw SearchError.serverError(httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)
        return decoded.results
    }

    func healthCheck() async -> Bool {
        guard let url = URL(string: "\(baseURL)/health") else { return false }
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    // MARK: - Face API

    func faceStatus() async throws -> FaceStatus {
        let data = try await get("/faces/status")
        return try JSONDecoder().decode(FaceStatus.self, from: data)
    }

    func faceClusters(show: String? = nil) async throws -> [FaceCluster] {
        var path = "/faces/clusters"
        if let show = show { path += "?show=\(show)" }
        let data = try await get(path)
        let response = try JSONDecoder().decode(ClustersResponse.self, from: data)
        return response.clusters
    }

    func detectFaces() async throws {
        try await post("/faces/detect", body: [:])
    }

    func detectProgress() async throws -> DetectProgress {
        let data = try await get("/faces/detect/progress")
        return try JSONDecoder().decode(DetectProgress.self, from: data)
    }

    func clusterFaces(tolerance: Double = 0.5) async throws {
        try await post("/faces/cluster", body: ["tolerance": tolerance])
    }

    func assignNewFaces() async throws {
        try await post("/faces/assign", body: [:])
    }

    func nameCluster(clusterId: Int, name: String) async throws {
        try await post("/faces/name", body: ["cluster_id": clusterId, "name": name] as [String: Any])
    }

    func renamePerson(personId: String, name: String) async throws {
        try await post("/faces/rename", body: ["person_id": personId, "name": name])
    }

    func mergeClusters(sourceId: Int, targetId: Int) async throws {
        try await post("/faces/merge", body: ["source_cluster_id": sourceId, "target_cluster_id": targetId] as [String: Any])
    }

    func ignoreCluster(clusterId: Int) async throws {
        try await post("/faces/ignore", body: ["cluster_id": clusterId] as [String: Any])
    }

    func unignoreCluster(clusterId: Int) async throws {
        try await post("/faces/unignore", body: ["cluster_id": clusterId] as [String: Any])
    }

    func unnameCluster(clusterId: Int) async throws {
        try await post("/faces/unname", body: ["cluster_id": clusterId] as [String: Any])
    }

    func getClusterFaces(clusterId: Int) async throws -> ClusterDetailResponse {
        let data = try await get("/faces/cluster/\(clusterId)/faces")
        return try JSONDecoder().decode(ClusterDetailResponse.self, from: data)
    }

    func removeFace(faceId: String) async throws {
        try await post("/faces/remove-face", body: ["face_id": faceId])
    }

    // MARK: - Helpers

    private func get(_ path: String) async throws -> Data {
        guard let url = URL(string: "\(baseURL)\(path)") else { throw SearchError.invalidURL }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw SearchError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        return data
    }

    private func post(_ path: String, body: [String: Any]) async throws {
        guard let url = URL(string: "\(baseURL)\(path)") else { throw SearchError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw SearchError.serverError((response as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }
}

enum SearchError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid search URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server error (HTTP \(code))"
        }
    }
}
