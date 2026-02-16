import SwiftUI

struct ThumbnailCard: View {
    let result: SearchResult
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail area (16:9 aspect ratio)
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: result.thumbnailURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholderView
                    default:
                        ZStack {
                            Color(nsColor: .controlBackgroundColor)
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(16.0 / 9.0, contentMode: .fit)
                .clipped()

                // Type badge + duration overlay
                HStack {
                    Text(result.typeLabel)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(result.typeColor.opacity(0.85))
                        .cornerRadius(4)

                    Spacer()

                    if let duration = result.durationFormatted {
                        Text(duration)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(4)
                    }
                }
                .padding(6)

                // Hover overlay with actions
                if isHovering {
                    Color.black.opacity(0.5)
                        .aspectRatio(16.0 / 9.0, contentMode: .fit)
                        .overlay {
                            HStack(spacing: 12) {
                                hoverButton(icon: "folder", label: "Reveal") {
                                    NSWorkspace.shared.activateFileViewerSelecting(
                                        [URL(fileURLWithPath: result.path)]
                                    )
                                }

                                hoverButton(icon: "doc.on.clipboard", label: "Copy") {
                                    let pasteboard = NSPasteboard.general
                                    pasteboard.clearContents()
                                    pasteboard.setString(result.path, forType: .string)
                                }
                            }
                        }
                        .transition(.opacity)
                }
            }
            .cornerRadius(6)

            // Filename below thumbnail
            Text(result.filename)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.horizontal, 4)
                .padding(.top, 6)
                .padding(.bottom, 2)

            // Description
            if let desc = result.description, !desc.isEmpty {
                Text(desc)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }

    private var placeholderView: some View {
        ZStack {
            Color(nsColor: .controlBackgroundColor)
            Image(systemName: result.typeIcon)
                .font(.system(size: 32))
                .foregroundColor(.secondary)
        }
    }

    private func hoverButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(width: 60, height: 50)
            .background(Color.white.opacity(0.15))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
