# Vault Search

Native macOS app for searching Northwoods' production media vault. Features a dark-mode thumbnail grid with AI-powered search results.

## Features

- **Thumbnail grid**: LazyVGrid layout with 16:9 aspect ratio cards
- **Dark mode**: Professional dark interface inspired by [Jumper](https://getjumper.io)
- **Hybrid search**: Semantic AI search + full-text keyword matching
- **Type badges**: Color-coded badges (blue=video, green=image, orange=audio)
- **Duration overlays**: Video duration shown on thumbnail cards
- **Hover actions**: Reveal in Finder and Copy Path appear on hover
- **Filter tabs**: Filter by All, Images, Video, or Audio
- **Debounced search**: 300ms delay for responsive typing
- **Live result count**: Shows match count and active query

## Requirements

- macOS 14.0 or later (Apple Silicon)
- [AVL Media Indexer](https://github.com/NorthwoodsCommunityChurch/avl-media-indexer) running on the Mac Pro (search API on port 8081)

## Installation

1. Download the latest `VaultSearch-...-aarch64.zip` from [Releases](https://github.com/NorthwoodsCommunityChurch/avl-vault-search/releases)
2. Extract the zip
3. Move `VaultSearch.app` to Applications
4. Try to open it (macOS will block it)
5. Go to System Settings > Privacy & Security
6. Click "Open Anyway"

## Usage

1. Make sure the Mac Pro search API is running (check `/health` on port 8081)
2. Open Vault Search
3. Type keywords in the search bar (e.g., "sunset", "easter", "worship")
4. Browse results in the thumbnail grid
5. Hover over a card to Reveal in Finder or Copy the file path
6. Use filter tabs to narrow results by media type

## Building from Source

```bash
# Generate Xcode project
xcodegen generate

# Build release
xcodebuild -scheme VaultSearch -configuration Release -derivedDataPath build build

# Run
open build/Build/Products/Release/VaultSearch.app
```

## Project Structure

```
avl-vault-search/
├── VaultSearch/
│   ├── VaultSearchApp.swift      # App entry point
│   ├── Info.plist                # ATS exception for local HTTP
│   ├── Models/
│   │   ├── SearchResult.swift    # Result model with thumbnail URL
│   │   └── SearchResponse.swift  # API response wrapper
│   ├── Services/
│   │   └── SearchService.swift   # Async API client
│   └── Views/
│       ├── SearchView.swift      # Main search + grid view
│       ├── ThumbnailCard.swift   # Thumbnail card with hover
│       ├── FilterTabsView.swift  # Media type filter tabs
│       └── EmptyStateView.swift  # Empty/error states
├── project.yml                   # XcodeGen project definition
├── CREDITS.md                    # Third-party credits
└── LICENSE                       # MIT License
```

## License

[MIT](LICENSE) - Copyright (c) 2026 Northwoods Community Church

## Credits

See [CREDITS.md](CREDITS.md) for full attribution.
