import Foundation

actor SearchService {
    private let baseURL = "http://10.10.11.173:8081"

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
