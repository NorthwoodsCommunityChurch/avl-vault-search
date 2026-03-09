import Foundation

@MainActor
class NetworkService: ObservableObject {
    @Published var results: [SearchResult] = []
    @Published var isSearching = false
    @Published var errorMessage: String?

    private let baseURL: String
    private let session: URLSession

    init(baseURL: String = "http://10.10.11.157:8081") {
        self.baseURL = baseURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 10
        self.session = URLSession(configuration: config)
    }

    func search(query: String) async {
        guard !query.isEmpty else {
            results = []
            return
        }

        isSearching = true
        errorMessage = nil

        do {
            var components = URLComponents(string: "\(baseURL)/search")!
            components.queryItems = [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "limit", value: "50")
            ]

            guard let url = components.url else {
                throw URLError(.badURL)
            }

            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }

            if httpResponse.statusCode != 200 {
                throw URLError(.badServerResponse)
            }

            let searchResponse = try JSONDecoder().decode(SearchResponse.self, from: data)
            results = searchResponse.results
        } catch let error as URLError where error.code == .timedOut || error.code == .cannotConnectToHost || error.code == .networkConnectionLost || error.code == .notConnectedToInternet {
            errorMessage = "Server offline — cannot reach search API"
            results = []
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
            results = []
        }

        isSearching = false
    }

    func getStatus() async -> IndexStatus? {
        do {
            guard let url = URL(string: "\(baseURL)/status") else {
                return nil
            }

            let (data, _) = try await session.data(from: url)
            return try JSONDecoder().decode(IndexStatus.self, from: data)
        } catch {
            return nil
        }
    }
}
