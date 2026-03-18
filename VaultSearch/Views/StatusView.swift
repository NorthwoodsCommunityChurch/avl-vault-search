import SwiftUI

struct StatusView: View {
    @State private var service = StatusService()

    private var cpuWorkers: [WorkerInfo] {
        guard let ws = service.workerStatus else { return [] }
        var workers = [
            WorkerInfo(
                name: "Face",
                isActive: ws.cpuWorkers.faceDetect.processing,
                currentTask: ws.cpuWorkers.faceDetect.currentTask,
                indexerQueue: ws.cpuWorkers.faceDetect.queue.crawler,
                apiQueue: ws.cpuWorkers.faceDetect.queue.api
            ),
            WorkerInfo(
                name: "Scene",
                isActive: ws.cpuWorkers.sceneDetect.active > 0,
                currentTask: nil,
                indexerQueue: ws.cpuWorkers.sceneDetect.queue.crawler,
                apiQueue: ws.cpuWorkers.sceneDetect.queue.api,
                detail: "\(ws.cpuWorkers.sceneDetect.active)/\(ws.cpuWorkers.sceneDetect.workers) workers"
            ),
        ]
        if let ala = ws.cpuWorkers.ala {
            workers.append(WorkerInfo(
                name: "ALA",
                isActive: ala.processing,
                currentTask: ala.currentTask,
                indexerQueue: 0,
                apiQueue: ala.queue.api
            ))
        }
        return workers
    }

    private var gpuWorkers: [WorkerInfo] {
        guard let ws = service.workerStatus else {
            // Fallback: use old GPU server data
            return service.servers.map { s in
                WorkerInfo(
                    name: s.name,
                    isActive: s.isProcessing,
                    isOnline: s.isOnline,
                    currentTask: nil,
                    indexerQueue: 0,
                    apiQueue: 0,
                    detail: s.model
                )
            }
        }
        return ws.gpus.map { gpu in
            WorkerInfo(
                name: gpu.name,
                isActive: gpu.processing,
                isOnline: gpu.online,
                currentTask: gpu.currentTask,
                indexerQueue: gpu.queue.crawler,
                apiQueue: gpu.queue.api,
                detail: gpu.model,
                orchestratorState: gpu.orchestratorState
            )
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: CPU Workers
                WorkerSection(title: "CPU", icon: "cpu", workers: cpuWorkers)

                // MARK: GPU Workers
                WorkerSection(title: "GPU", icon: "rectangle.stack.fill", workers: gpuWorkers)

                // MARK: Crawler
                CrawlerCard(scanner: service.scanner)

                // MARK: Overall Progress
                IndexerSummaryCard(counts: service.indexer)

                Spacer()
            }
            .padding(20)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear { service.startPolling() }
        .onDisappear { service.stopPolling() }
    }
}

// MARK: - Data Model

struct WorkerInfo: Identifiable {
    let id = UUID()
    let name: String
    var isActive: Bool
    var isOnline: Bool = true
    var currentTask: CurrentTaskInfo?
    var indexerQueue: Int
    var apiQueue: Int
    var detail: String? = nil
    var orchestratorState: String? = nil  // Pro 580X only

    /// Which queue the worker is currently pulling from ("crawler" or "api"), or nil if idle
    var activeSource: String? {
        currentTask?.source
    }

    var isOrchestrated: Bool { orchestratorState != nil }

    var orchestratorLabel: String? {
        guard let state = orchestratorState else { return nil }
        switch state {
        case "gemma_ready": return "Gemma Ready"
        case "gemma_loading": return "Loading Gemma..."
        case "whisper_busy": return "Transcribing"
        case "whisper_loading": return "Loading Whisper..."
        case "idle": return "Idle"
        default: return state
        }
    }
}

// MARK: - Worker Section (CPU or GPU row)

struct WorkerSection: View {
    let title: String
    let icon: String
    let workers: [WorkerInfo]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(title: title, icon: icon)

            HStack(alignment: .top, spacing: 16) {
                ForEach(workers) { worker in
                    WorkerCard(worker: worker)
                }
            }
        }
    }
}

// MARK: - Section Label

struct SectionLabel: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.secondary)
    }
}

// MARK: - Worker Status Indicator

struct WorkerStatusIndicator: View {
    let isOnline: Bool
    let isActive: Bool
    @State private var isSpinning = false

    var body: some View {
        if !isOnline {
            Circle()
                .fill(Color(nsColor: .systemGray))
                .frame(width: 10, height: 10)
        } else if isActive {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.green)
                .rotationEffect(.degrees(isSpinning ? 360 : 0))
                .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: isSpinning)
                .onAppear { isSpinning = true }
                .frame(width: 10, height: 10)
        } else {
            Circle()
                .fill(Color(nsColor: .systemGray).opacity(0.4))
                .frame(width: 10, height: 10)
        }
    }
}

// MARK: - Worker Card

struct WorkerCard: View {
    let worker: WorkerInfo

    var body: some View {
        VStack(spacing: 0) {
            // Top section: name, detail, task — fixed height
            VStack(alignment: .leading, spacing: 4) {
                // Worker name + status indicator
                HStack(spacing: 6) {
                    WorkerStatusIndicator(isOnline: worker.isOnline, isActive: worker.isActive)

                    Text(worker.name)
                        .font(.system(size: 13, weight: .semibold))

                    if !worker.isOnline {
                        Text("Offline")
                            .font(.system(size: 10))
                            .foregroundColor(.red.opacity(0.8))
                    }
                }

                // Detail text (model name, worker count) — reserve line even if empty
                if worker.orchestratorLabel != nil {
                    HStack(spacing: 4) {
                        Text(worker.detail ?? "")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        OrchestratorBadge(state: worker.orchestratorState ?? "")
                    }
                } else {
                    Text(worker.detail ?? " ")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .opacity(worker.detail != nil ? 1 : 0)
                }

                // Current task — fixed height, hidden content when no task
                HStack(spacing: 4) {
                    if let task = worker.currentTask {
                        SourceBadge(source: task.source)
                        Text(task.file)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    } else {
                        Text(" ")
                            .font(.system(size: 10))
                    }
                }
                .frame(height: 16, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer().frame(height: 10)

            // Bracket visualization: Worker → splits to Indexer and API
            WorkerBracketView(
                indexerCount: worker.indexerQueue,
                apiCount: worker.apiQueue,
                activeSource: worker.activeSource
            )
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Worker Bracket View
// Shows a bracket from the worker splitting down to Indexer and API queue counts.
// The active path (based on currentTask.source) is highlighted.

struct WorkerBracketView: View {
    let indexerCount: Int
    let apiCount: Int
    let activeSource: String?  // "crawler" = indexer active, "api" = api active, nil = idle

    private var indexerActive: Bool { activeSource == "crawler" }
    private var apiActive: Bool { activeSource == "api" }

    private var indexerColor: Color {
        if indexerActive { return .green }
        return indexerCount > 0 ? .secondary : .secondary.opacity(0.3)
    }

    private var apiColor: Color {
        if apiActive { return .blue }
        return apiCount > 0 ? .secondary : .secondary.opacity(0.3)
    }

    var body: some View {
        VStack(spacing: 0) {
            // The bracket shape connecting worker to queues
            SplitBracketShape(activeSource: activeSource)
                .frame(height: 20)

            // Queue labels and counts
            HStack(spacing: 0) {
                // Indexer column
                VStack(spacing: 2) {
                    Text(formatCount(indexerCount))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(indexerActive ? .green : (indexerCount > 0 ? .secondary : .secondary.opacity(0.3)))

                    Text("Indexer")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(indexerColor)
                }
                .frame(maxWidth: .infinity)

                // API column
                VStack(spacing: 2) {
                    Text(formatCount(apiCount))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(apiActive ? .blue : (apiCount > 0 ? .secondary : .secondary.opacity(0.3)))

                    Text("API")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(apiColor)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func formatCount(_ n: Int) -> String {
        if n >= 100_000 {
            return String(format: "%.0fK", Double(n) / 1000.0)
        }
        if n >= 1000 {
            return String(format: "%.1fK", Double(n) / 1000.0)
        }
        return "\(n)"
    }
}

// MARK: - Split Bracket Shape
// Draws a bracket from center top splitting down to left and right legs.
//
//        │           ← stem (from worker above)
//   ┌────┴────┐      ← horizontal bar
//   │         │      ← left and right legs
//
// The active side is drawn with a highlighted color.

struct SplitBracketShape: View {
    let activeSource: String?  // "crawler" or "api" or nil

    private var leftActive: Bool { activeSource == "crawler" }
    private var rightActive: Bool { activeSource == "api" }

    private var leftColor: Color {
        leftActive ? .green : Color.secondary.opacity(0.2)
    }
    private var rightColor: Color {
        rightActive ? .blue : Color.secondary.opacity(0.2)
    }
    private var stemColor: Color {
        if leftActive { return .green }
        if rightActive { return .blue }
        return Color.secondary.opacity(0.2)
    }

    var body: some View {
        GeometryReader { geo in
            let midX = geo.size.width / 2
            let leftX = geo.size.width * 0.25
            let rightX = geo.size.width * 0.75
            let stemBottom: CGFloat = 6
            let barY: CGFloat = 6
            let legBottom = geo.size.height

            // Stem from top center down to bar
            Path { p in
                p.move(to: CGPoint(x: midX, y: 0))
                p.addLine(to: CGPoint(x: midX, y: stemBottom))
            }
            .stroke(stemColor, lineWidth: leftActive || rightActive ? 2 : 1)

            // Left half of bar + left leg
            Path { p in
                p.move(to: CGPoint(x: midX, y: barY))
                p.addLine(to: CGPoint(x: leftX, y: barY))
                p.addLine(to: CGPoint(x: leftX, y: legBottom))
            }
            .stroke(leftColor, lineWidth: leftActive ? 2 : 1)

            // Right half of bar + right leg
            Path { p in
                p.move(to: CGPoint(x: midX, y: barY))
                p.addLine(to: CGPoint(x: rightX, y: barY))
                p.addLine(to: CGPoint(x: rightX, y: legBottom))
            }
            .stroke(rightColor, lineWidth: rightActive ? 2 : 1)
        }
    }
}

// MARK: - Source Badge

struct SourceBadge: View {
    let source: String

    var body: some View {
        Text(source == "api" ? "API" : "Crawler")
            .font(.system(size: 9, weight: .semibold))
            .foregroundColor(source == "api" ? .white : .secondary)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(source == "api" ? Color.blue : Color(nsColor: .systemGray).opacity(0.3))
            )
    }
}

// MARK: - Crawler Card

struct CrawlerCard: View {
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

    private var subtitle: String {
        switch scanner.state {
        case "scanning":
            if !scanner.currentFolder.isEmpty {
                return URL(fileURLWithPath: scanner.currentFolder).lastPathComponent
            }
            return "\(scanner.filesScanned) files scanned"
        case "sleeping":
            if let secs = scanner.nextScanIn {
                if secs < 60 { return "Next scan in \(secs)s" }
                return "Next scan in \(secs / 60)m"
            }
            return ""
        default:
            return ""
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(title: "Crawler", icon: "folder.badge.gearshape")

            HStack(spacing: 10) {
                Circle()
                    .fill(stateColor)
                    .frame(width: 7, height: 7)
                    .shadow(color: scanner.state == "scanning" ? .green.opacity(0.5) : .clear, radius: 3)

                Text(stateLabel)
                    .font(.system(size: 12, weight: .medium))

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if scanner.state == "scanning" && scanner.filesNew > 0 {
                    Text("\(scanner.filesNew) new")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }
}

// MARK: - Indexer Summary Card

struct IndexerSummaryCard: View {
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(title: "Overall Progress", icon: "chart.bar.fill")

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(formattedIndexed)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                    Text("/ \(formattedTotal) files")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.0f%%", counts.progress * 100))
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.blue)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(nsColor: .separatorColor))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(LinearGradient(colors: [.blue.opacity(0.7), .blue], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * counts.progress)
                            .animation(.easeInOut(duration: 0.6), value: counts.progress)
                    }
                }
                .frame(height: 5)

                HStack(spacing: 14) {
                    if counts.pending > 0 {
                        StatBadge(value: counts.pending, label: "pending", color: .orange)
                    }
                    if counts.indexing > 0 {
                        StatBadge(value: counts.indexing, label: "in queue", color: .blue)
                    }
                    if counts.error > 0 {
                        StatBadge(value: counts.error, label: "errors", color: .red)
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
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
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

// MARK: - Orchestrator Badge

struct OrchestratorBadge: View {
    let state: String

    private var label: String {
        switch state {
        case "gemma_ready": return "Gemma Ready"
        case "gemma_loading": return "Loading Gemma"
        case "whisper_busy": return "Transcribing"
        case "whisper_loading": return "Loading Whisper"
        case "idle": return "Idle"
        default: return state
        }
    }

    private var color: Color {
        switch state {
        case "gemma_ready": return .green
        case "whisper_busy": return .teal
        case "gemma_loading", "whisper_loading": return .yellow
        default: return Color(nsColor: .systemGray)
        }
    }

    var body: some View {
        Text(label)
            .font(.system(size: 9, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(
                RoundedRectangle(cornerRadius: 3)
                    .fill(color.opacity(0.15))
            )
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
