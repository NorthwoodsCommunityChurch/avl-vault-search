import SwiftUI

struct StatusView: View {
    @State private var service = StatusService()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {

                // MARK: GPU Servers
                VStack(alignment: .leading, spacing: 8) {
                    Text("GPU Servers")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.8)

                    VStack(spacing: 5) {
                        ForEach(service.servers) { server in
                            GPUServerRow(server: server)
                        }
                    }
                }

                Divider()

                // MARK: Scanner
                VStack(alignment: .leading, spacing: 8) {
                    Text("Scanner")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.8)

                    ScannerCard(scanner: service.scanner)
                }

                Divider()

                // MARK: Media Indexer
                VStack(alignment: .leading, spacing: 8) {
                    Text("Media Indexer")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.8)

                    IndexerStatusCard(counts: service.indexer)
                }

                Spacer()
            }
            .padding(16)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear { service.startPolling() }
        .onDisappear { service.stopPolling() }
    }
}

// MARK: - GPU Server Row

struct GPUServerRow: View {
    let server: GPUServerStatus

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Circle()
                    .fill(server.isOnline ? Color.green : Color(nsColor: .systemGray))
                    .frame(width: 7, height: 7)
                    .shadow(color: server.isOnline ? .green.opacity(0.6) : .clear, radius: 4)

                Text(server.name)
                    .font(.system(size: 12, weight: .medium))

                Text(server.model)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Spacer()

                Text(statusLabel(server))
                    .font(.system(size: 11))
                    .foregroundColor(statusColor(server))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)

            ActivityBar(isOnline: server.isOnline, isProcessing: server.isProcessing)
                .frame(height: 2)
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }

    private func statusLabel(_ s: GPUServerStatus) -> String {
        if !s.isOnline { return "Offline" }
        return s.isProcessing ? "Processing" : "Idle"
    }

    private func statusColor(_ s: GPUServerStatus) -> Color {
        if !s.isOnline { return .secondary }
        return s.isProcessing ? .blue : Color(nsColor: .systemGray)
    }
}

// MARK: - Activity Bar

struct ActivityBar: View {
    let isOnline: Bool
    let isProcessing: Bool
    @State private var phase: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color(nsColor: .separatorColor))

                // Fill
                if isOnline {
                    if isProcessing {
                        // Animated shimmer for processing
                        RoundedRectangle(cornerRadius: 1)
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.3), .blue, .blue.opacity(0.3)],
                                    startPoint: .init(x: phase - 0.5, y: 0),
                                    endPoint: .init(x: phase + 0.5, y: 0)
                                )
                            )
                            .onAppear {
                                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                                    phase = 1.5
                                }
                            }
                    } else {
                        // Solid dim fill for idle
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(nsColor: .systemGray).opacity(0.3))
                            .frame(width: geo.size.width * 0.15)
                    }
                }
            }
        }
    }
}

// MARK: - Scanner Card

struct ScannerCard: View {
    let scanner: ScannerStatus

    private var stateLabel: String {
        switch scanner.state {
        case "scanning":   return "Scanning"
        case "processing": return "Processing"
        case "sleeping":   return "Sleeping"
        default:           return "Idle"
        }
    }

    private var stateColor: Color {
        switch scanner.state {
        case "scanning":   return .green
        case "processing": return .blue
        case "sleeping":   return Color(nsColor: .systemGray)
        default:           return Color(nsColor: .systemGray)
        }
    }

    private var subtitleText: String {
        switch scanner.state {
        case "scanning":
            if !scanner.currentFolder.isEmpty {
                return URL(fileURLWithPath: scanner.currentFolder).lastPathComponent
            }
            return "\(scanner.filesScanned) files scanned"
        case "processing":
            return "Running AI descriptions on pending files"
        case "sleeping":
            if let secs = scanner.nextScanIn {
                if secs < 60 { return "Next scan in \(secs)s" }
                return "Next scan in \(secs / 60)m \(secs % 60)s"
            }
            return ""
        default:
            return "Watching vault for changes"
        }
    }

    private var rightLabel: String {
        if scanner.state == "scanning" && scanner.filesNew > 0 {
            return "\(scanner.filesNew) new"
        }
        if scanner.state == "scanning" && scanner.filesScanned > 0 {
            return "\(scanner.filesScanned) scanned"
        }
        return ""
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Circle()
                    .fill(stateColor)
                    .frame(width: 7, height: 7)
                    .shadow(color: scanner.state == "scanning" ? Color.green.opacity(0.6) : .clear, radius: 4)

                Text(stateLabel)
                    .font(.system(size: 12, weight: .medium))

                Text(subtitleText)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                if !rightLabel.isEmpty {
                    Text(rightLabel)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)

            ActivityBar(
                isOnline: scanner.state != "idle",
                isProcessing: scanner.state == "scanning" || scanner.state == "processing"
            )
            .frame(height: 2)
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Indexer Status Card

struct IndexerStatusCard: View {
    let counts: IndexerCounts

    private let typeRows: [(key: String, label: String, icon: String, color: Color)] = [
        ("video",         "Video",          "film",               .blue),
        ("image",         "Images",         "photo",              .purple),
        ("audio",         "Audio",          "waveform",           .orange),
        ("transcription", "Transcription",  "waveform.badge.mic", .teal),
    ]

    private var formattedIndexed: String {
        NumberFormatter.localizedString(from: NSNumber(value: counts.indexed), number: .decimal)
    }

    private var formattedTotal: String {
        NumberFormatter.localizedString(from: NSNumber(value: counts.total), number: .decimal)
    }

    private var lastScannedText: String {
        guard let date = counts.lastUpdated else { return "—" }
        let secs = Int(-date.timeIntervalSinceNow)
        if secs < 60 { return "just now" }
        if secs < 3600 { return "\(secs / 60)m ago" }
        return "\(secs / 3600)h ago"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Counts row
            HStack(alignment: .firstTextBaseline) {
                Text(formattedIndexed)
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                Text("/ \(formattedTotal) files indexed")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.0f%%", counts.progress * 100))
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.blue)
            }

            // Overall progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(nsColor: .separatorColor))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.7), Color.blue],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * counts.progress)
                        .animation(.easeInOut(duration: 0.6), value: counts.progress)
                }
            }
            .frame(height: 5)

            // Detail badges
            HStack(spacing: 14) {
                if counts.indexing > 0 {
                    StatBadge(value: counts.indexing, label: "in queue", color: .blue)
                }
                if counts.pending > 0 {
                    StatBadge(value: counts.pending, label: "pending", color: .orange)
                }
                if counts.error > 0 {
                    StatBadge(value: counts.error, label: "errors", color: .red)
                }
                if counts.offline > 0 {
                    StatBadge(value: counts.offline, label: "offline", color: .secondary)
                }

                Spacer()

                if counts.lastUpdated != nil {
                    Label(lastScannedText, systemImage: "arrow.clockwise")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            // Per-type breakdown
            if !counts.byType.isEmpty {
                Divider()
                    .padding(.vertical, 2)

                VStack(spacing: 6) {
                    ForEach(typeRows, id: \.key) { row in
                        if let tc = counts.byType[row.key], tc.total > 0 {
                            TypeProgressRow(
                                label: row.label,
                                icon: row.icon,
                                color: row.color,
                                counts: tc
                            )
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
    }
}

// MARK: - Type Progress Row

struct TypeProgressRow: View {
    let label: String
    let icon: String
    let color: Color
    let counts: TypeCounts

    private var formattedIndexed: String {
        NumberFormatter.localizedString(from: NSNumber(value: counts.indexed), number: .decimal)
    }

    private var formattedTotal: String {
        NumberFormatter.localizedString(from: NSNumber(value: counts.total), number: .decimal)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(label, systemImage: icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(color)
                Spacer()
                Text("\(formattedIndexed) / \(formattedTotal)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text(String(format: "%.0f%%", counts.progress * 100))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 34, alignment: .trailing)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(nsColor: .separatorColor))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.75))
                        .frame(width: geo.size.width * counts.progress)
                        .animation(.easeInOut(duration: 0.6), value: counts.progress)
                }
            }
            .frame(height: 3)
        }
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Text("\(value)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
}
