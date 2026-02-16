import SwiftUI

struct EmptyStateView: View {
    let hasSearchText: Bool
    let hasError: Bool

    var body: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))

            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)

            Text(subtitle)
                .font(.system(size: 13))
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    private var icon: String {
        if hasError {
            return "wifi.exclamationmark"
        } else if hasSearchText {
            return "magnifyingglass"
        } else {
            return "photo.on.rectangle.angled"
        }
    }

    private var title: String {
        if hasError {
            return "Connection Issue"
        } else if hasSearchText {
            return "No Results"
        } else {
            return "Search the Vault"
        }
    }

    private var subtitle: String {
        if hasError {
            return "Make sure the Mac Pro is running\nand the search API is active on port 8081"
        } else if hasSearchText {
            return "Try different keywords or check\nif the file has been indexed"
        } else {
            return "Type keywords to search across\nimages, video, and audio files"
        }
    }
}
