import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var results: [SearchResult] = []
    @State private var isSearching = false
    @State private var errorMessage = ""
    @State private var selectedFilter: MediaFilter = .all
    @State private var searchTask: Task<Void, Never>?

    private let service = SearchService()

    private let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 280), spacing: 16)
    ]

    var filteredResults: [SearchResult] {
        switch selectedFilter {
        case .all:
            return results
        case .images:
            return results.filter { $0.type == "image" }
        case .video:
            return results.filter { $0.type == "video" }
        case .audio:
            return results.filter { $0.type == "audio" }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))

                    TextField("Search vault media...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16))
                        .onChange(of: searchText) { _, newValue in
                            debounceSearch(query: newValue)
                        }
                        .onSubmit {
                            performSearch(query: searchText)
                        }

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            results = []
                            errorMessage = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    if isSearching {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 20, height: 20)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)

                // Result count + filter tabs
                if !results.isEmpty {
                    HStack {
                        Text("'\(searchText)' in \(results.count) files")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)

                        Spacer()

                        FilterTabsView(
                            selected: $selectedFilter,
                            totalCount: results.count,
                            imageCnt: results.filter { $0.type == "image" }.count,
                            videoCnt: results.filter { $0.type == "video" }.count,
                            audioCnt: results.filter { $0.type == "audio" }.count
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()

            // Error message
            if !errorMessage.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding()
            }

            // Content area
            if filteredResults.isEmpty && !isSearching {
                EmptyStateView(
                    hasSearchText: !searchText.isEmpty,
                    hasError: !errorMessage.isEmpty
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredResults) { result in
                            ThumbnailCard(result: result)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func debounceSearch(query: String) {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            if !Task.isCancelled {
                await performSearchAsync(query: query)
            }
        }
    }

    private func performSearch(query: String) {
        searchTask?.cancel()
        searchTask = Task {
            await performSearchAsync(query: query)
        }
    }

    @MainActor
    private func performSearchAsync(query: String) async {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            results = []
            errorMessage = ""
            return
        }

        isSearching = true
        errorMessage = ""

        do {
            let searchResults = try await service.search(query: trimmed)
            results = searchResults
        } catch {
            errorMessage = error.localizedDescription
        }

        isSearching = false
    }
}

enum MediaFilter: String, CaseIterable {
    case all = "All"
    case images = "Images"
    case video = "Video"
    case audio = "Audio"
}
