import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var networkService = NetworkService()
    @State private var searchText = ""
    @State private var debounceTask: Task<Void, Never>?

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)

                TextField("Search vault media...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .onChange(of: searchText) { newValue in
                        debounceSearch(query: newValue)
                    }

                if networkService.isSearching {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 16, height: 16)
                } else if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Results list
            if let errorMessage = networkService.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if searchText.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "film.stack")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Search the vault")
                        .font(.title2)
                    Text("Enter keywords to find media")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if networkService.results.isEmpty && !networkService.isSearching {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No results found")
                        .font(.title2)
                    Text("Try different keywords")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(networkService.results) { result in
                            ResultRow(result: result)
                        }
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }

    private func debounceSearch(query: String) {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            if !Task.isCancelled {
                await networkService.search(query: query)
            }
        }
    }
}

struct ResultRow: View {
    let result: SearchResult

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // File type icon
            Image(systemName: fileIcon)
                .font(.system(size: 28))
                .foregroundColor(fileColor)
                .frame(width: 40)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(result.filename)
                    .font(.system(size: 13, weight: .medium))

                Text(result.displayDescription)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Text(result.fileInfo)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)

                    if let tags = result.tags, !tags.isEmpty {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(tags)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Actions
            HStack(spacing: 8) {
                Button(action: { revealInFinder() }) {
                    Image(systemName: "arrow.forward.circle")
                }
                .buttonStyle(.plain)
                .help("Reveal in Finder")

                Button(action: { copyPath() }) {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.plain)
                .help("Copy path")
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            revealInFinder()
        }
    }

    private var fileIcon: String {
        switch result.fileType.lowercased() {
        case "video": return "film"
        case "image": return "photo"
        case "audio": return "waveform"
        default: return "doc"
        }
    }

    private var fileColor: Color {
        switch result.fileType.lowercased() {
        case "video": return .blue
        case "image": return .purple
        case "audio": return .green
        default: return .gray
        }
    }

    private func revealInFinder() {
        let url = URL(fileURLWithPath: result.path)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private func copyPath() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(result.path, forType: .string)
    }
}

#Preview {
    ContentView()
}
