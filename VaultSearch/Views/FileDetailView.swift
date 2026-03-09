import SwiftUI

struct FileDetailView: View {
    let result: SearchResult
    @Environment(\.dismiss) private var dismiss

    @State private var currentKeyframeIndex: Int = 0
    @State private var currentImage: NSImage? = nil
    @State private var isLoadingImage = false
    @State private var selectedTimestamp: Double = 0

    private var duration: Double { result.duration ?? 1 }

    private var allMatches: [AnyMatch] {
        var matches: [AnyMatch] = []
        for kf in result.matchedKeyframes {
            matches.append(AnyMatch(timestamp: kf.timestamp, type: .visual, label: kf.description))
        }
        for seg in result.matchedSegments {
            matches.append(AnyMatch(timestamp: seg.start, type: .speech, label: seg.text))
        }
        for face in result.matchedFaces {
            matches.append(AnyMatch(timestamp: face.timestamp, type: .face, label: face.name))
        }
        return matches.sorted { $0.timestamp < $1.timestamp }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(result.filename)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            Divider()

            // Preview area
            ZStack {
                Color.black
                if isLoadingImage {
                    ProgressView()
                        .tint(.white)
                } else if let img = currentImage {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: result.typeIcon)
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                }

                HStack {
                    Button { navigateKeyframe(by: -1) } label: {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .disabled(currentKeyframeIndex <= 0)

                    Spacer()

                    Button { navigateKeyframe(by: 1) } label: {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .disabled(currentKeyframeIndex >= result.keyframeCount - 1)
                }
                .padding(.horizontal, 12)
            }
            .frame(height: 220)

            HStack {
                Text("Frame \(currentKeyframeIndex + 1) of \(result.keyframeCount)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                Spacer()
                Text(SearchResult.formatTimestamp(selectedTimestamp))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)

            Divider()

            if duration > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TIMELINE")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.2))
                                .frame(height: 24)

                            ForEach(Array(result.matchedKeyframes.enumerated()), id: \.offset) { _, kf in
                                markerView(color: .orange, icon: "eye.fill", timestamp: kf.timestamp, totalWidth: geo.size.width)
                            }

                            ForEach(Array(result.matchedSegments.enumerated()), id: \.offset) { _, seg in
                                markerView(color: .blue, icon: "waveform", timestamp: seg.start, totalWidth: geo.size.width)
                            }

                            ForEach(Array(result.matchedFaces.enumerated()), id: \.offset) { _, face in
                                markerView(color: .cyan, icon: "person.fill", timestamp: face.timestamp, totalWidth: geo.size.width)
                            }
                        }
                    }
                    .frame(height: 24)
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 8)

                Divider()
            }

            if allMatches.isEmpty {
                Text("No specific match markers for this result")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("MATCHES")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            .padding(.bottom, 4)

                        ForEach(Array(allMatches.enumerated()), id: \.offset) { _, match in
                            matchRow(match)
                        }
                    }
                }
            }
        }
        .frame(minWidth: 700, minHeight: 520)
        .onAppear {
            Task { await loadKeyframe(index: 0) }
        }
    }

    private func markerView(color: Color, icon: String, timestamp: Double, totalWidth: CGFloat) -> some View {
        let x = CGFloat(timestamp / duration) * totalWidth
        return Button {
            seekTo(timestamp: timestamp)
        } label: {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color)
                .frame(width: 16, height: 16)
                .background(Color.black.opacity(0.4))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .position(x: max(8, min(x, totalWidth - 8)), y: 12)
    }

    private func matchRow(_ match: AnyMatch) -> some View {
        Button {
            seekTo(timestamp: match.timestamp)
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: match.type.icon)
                    .font(.system(size: 12))
                    .foregroundColor(match.type.color)
                    .frame(width: 16)

                Text(SearchResult.formatTimestamp(match.timestamp))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 60, alignment: .leading)

                Text(match.label)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.primary.opacity(0.03))
        .overlay(Divider().opacity(0.5), alignment: .bottom)
    }

    private func seekTo(timestamp: Double) {
        selectedTimestamp = timestamp
        guard duration > 0, result.keyframeCount > 0 else { return }
        let ratio = timestamp / duration
        let idx = min(Int(ratio * Double(result.keyframeCount)), result.keyframeCount - 1)
        currentKeyframeIndex = idx
        Task { await loadKeyframe(index: idx) }
    }

    private func navigateKeyframe(by delta: Int) {
        let newIdx = max(0, min(currentKeyframeIndex + delta, result.keyframeCount - 1))
        currentKeyframeIndex = newIdx
        Task { await loadKeyframe(index: newIdx) }
    }

    @MainActor
    private func loadKeyframe(index: Int) async {
        guard let url = result.keyframeURL(index: index) else { return }
        isLoadingImage = true
        if let (data, _) = try? await URLSession.shared.data(from: url),
           let img = NSImage(data: data) {
            currentImage = img
        }
        isLoadingImage = false
    }
}

struct AnyMatch {
    let timestamp: Double
    let type: MatchType
    let label: String

    enum MatchType {
        case visual, speech, face

        var icon: String {
            switch self {
            case .visual: return "eye.fill"
            case .speech: return "waveform"
            case .face: return "person.fill"
            }
        }

        var color: Color {
            switch self {
            case .visual: return .orange
            case .speech: return .blue
            case .face: return .cyan
            }
        }
    }
}
