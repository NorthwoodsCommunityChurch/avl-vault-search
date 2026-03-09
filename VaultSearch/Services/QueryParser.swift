import Foundation
import NaturalLanguage

struct ParsedQuery {
    var persons: [String] = []
    var places: [String] = []
    var topics: [String] = []
    var rawQuery: String = ""
}

@MainActor
class QueryParser: ObservableObject {

    func parse(_ query: String, knownPersons: [String] = []) async -> ParsedQuery {
        return parseWithNLTagger(query, knownPersons: knownPersons)
    }

    private func parseWithNLTagger(_ query: String, knownPersons: [String]) -> ParsedQuery {
        var parsed = ParsedQuery(rawQuery: query)
        let lowercased = query.lowercased()

        for person in knownPersons {
            if lowercased.contains(person.lowercased()) {
                parsed.persons.append(person)
            }
        }

        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = query
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation, .joinNames]

        tagger.enumerateTags(in: query.startIndex..<query.endIndex,
                             unit: .word,
                             scheme: .nameType,
                             options: options) { tag, range in
            let token = String(query[range])
            switch tag {
            case .personalName:
                if !parsed.persons.contains(where: { $0.lowercased() == token.lowercased() }) {
                    parsed.persons.append(token)
                }
            case .placeName:
                parsed.places.append(token)
            default:
                break
            }
            return true
        }

        let stopWords: Set<String> = ["the", "a", "an", "in", "on", "at", "for", "with",
                                       "and", "or", "but", "is", "are", "was", "were",
                                       "show", "find", "search", "where", "when", "who",
                                       "me", "my", "of", "to", "from", "about", "any", "all"]
        let allNamedTokens = Set((parsed.persons + parsed.places).map { $0.lowercased() })
        let words = query.components(separatedBy: .whitespacesAndNewlines)
            .map { $0.trimmingCharacters(in: .punctuationCharacters).lowercased() }
            .filter { !$0.isEmpty && !stopWords.contains($0) && $0.count > 2 && !allNamedTokens.contains($0) }

        var seen = Set<String>()
        for w in words {
            if seen.insert(w).inserted {
                parsed.topics.append(w)
            }
        }

        return parsed
    }
}
