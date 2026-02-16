# Vault Search

Native macOS app for searching the Northwoods media vault via the search API on the Mac Pro.

## Architecture

- **SwiftUI** app targeting macOS 14.0+
- Connects to the media indexer search API at `http://10.10.11.173:8081`
- Dark mode only (forced via `.preferredColorScheme(.dark)`)
- Uses XcodeGen (`project.yml`) to generate the Xcode project

## API Dependency

This app requires the media indexer search API from the [avl-media-indexer](https://github.com/NorthwoodsCommunityChurch/avl-media-indexer) project to be running on the Mac Pro.

### Endpoints Used

- `GET /search?q=<query>&limit=50` — search for media files
- `GET /thumbnail?id=<file_id>` — get thumbnail image for a file
- `GET /health` — check if the API is running

### Server Address

Hardcoded to `10.10.11.173:8081` (Mac Pro on the Northwoods production network).

## Project Structure

```
VaultSearch/
├── VaultSearchApp.swift          # Entry point, window config
├── Info.plist                    # ATS exception for local HTTP
├── Models/
│   ├── SearchResult.swift        # Codable model with thumbnail URL, badges
│   └── SearchResponse.swift      # API response wrapper
├── Services/
│   └── SearchService.swift       # Async API client
└── Views/
    ├── SearchView.swift          # Search bar + filter tabs + LazyVGrid
    ├── ThumbnailCard.swift       # Thumbnail card with hover actions
    ├── FilterTabsView.swift      # All | Images | Video | Audio tabs
    └── EmptyStateView.swift      # Empty/error/loading states
```

## Building

```bash
xcodegen generate
xcodebuild -scheme VaultSearch -configuration Release -derivedDataPath build build
open build/Build/Products/Release/VaultSearch.app
```

## ATS Configuration

The app uses a custom Info.plist with `NSAllowsLocalNetworking = true` to allow HTTP connections to the local network Mac Pro. This requires `GENERATE_INFOPLIST_FILE: false` in project.yml.

## Known Issues

- Custom Info.plist can cause crashes if deployment target or signing settings are wrong. Current working config: macOS 14.0, ENABLE_HARDENED_RUNTIME: false, CODE_SIGN_IDENTITY: "-"
