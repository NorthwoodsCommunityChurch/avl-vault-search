import Foundation

struct SearchResponse: Codable {
    let query: String
    let count: Int
    let results: [SearchResult]
}
