import SwiftUI

struct FacesView: View {
    @State private var clusters: [FaceCluster] = []
    @State private var ignoredClusters: [FaceCluster] = []
    @State private var status: FaceStatus?
    @State private var isLoading = false
    @State private var actionMessage = ""
    @State private var errorMessage = ""
    @State private var selectedClusterIds: Set<Int> = []
    @State private var selectedIgnoredIds: Set<Int> = []
    @State private var detectProgress: DetectProgress?
    @State private var progressPollTask: Task<Void, Never>?
    @State private var showIgnored = false

    private let service = SearchService()

    private var namedClusters: [FaceCluster] {
        clusters.filter { $0.isNamed }.sorted { $0.personName ?? "" < $1.personName ?? "" }
    }

    private var unnamedClusters: [FaceCluster] {
        clusters.filter { !$0.isNamed }.sorted { $0.faceCount > $1.faceCount }
    }

    private var isDetecting: Bool {
        detectProgress?.running == true
    }

    var body: some View {
        VStack(spacing: 0) {
            // Stats + actions bar
            VStack(spacing: 8) {
                // Stats row
                if let s = status {
                    HStack(spacing: 16) {
                        statBadge(label: "Faces", value: s.totalFaces, icon: "face.smiling")
                        statBadge(label: "People", value: s.namedPersons, icon: "person.2")
                        statBadge(label: "Unnamed", value: s.unnamedClusters, icon: "questionmark.circle")
                        statBadge(label: "Unscanned", value: s.filesWithoutFaceScan, icon: "doc.badge.clock")
                        Spacer()
                    }
                }

                // Detection progress bar
                if let progress = detectProgress, progress.running {
                    VStack(spacing: 4) {
                        HStack {
                            Image(systemName: "faceid")
                                .font(.system(size: 11))
                                .foregroundColor(.blue)
                            Text("Detecting faces...")
                                .font(.system(size: 11, weight: .medium))
                            Spacer()
                            Text("\(progress.processed) / \(progress.total)")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                            Text("(\(progress.facesFound) found)")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }

                        ProgressView(value: progress.total > 0 ? Double(progress.processed) / Double(progress.total) : 0)
                            .tint(.blue)

                        if !progress.currentFile.isEmpty {
                            Text(progress.currentFile)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(10)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }

                // Action buttons
                HStack(spacing: 8) {
                    actionButton(label: "Scan Faces", icon: "faceid", color: .blue) {
                        await runAction("Starting scan...") {
                            try await service.detectFaces()
                        }
                        await pollProgressOnce()
                        if isDetecting {
                            startProgressPolling()
                        }
                    }
                    .disabled(isDetecting)

                    actionButton(label: "Cluster", icon: "rectangle.3.group", color: .purple) {
                        await runAction("Clustering...") {
                            try await service.clusterFaces()
                        }
                    }

                    actionButton(label: "Auto-assign", icon: "person.badge.plus", color: .green) {
                        await runAction("Assigning...") {
                            try await service.assignNewFaces()
                        }
                    }

                    if selectedClusterIds.count == 2 {
                        let ids = Array(selectedClusterIds)
                        actionButton(label: "Merge Selected", icon: "arrow.triangle.merge", color: .orange) {
                            await runAction("Merging...") {
                                try await service.mergeClusters(sourceId: ids[0], targetId: ids[1])
                            }
                            selectedClusterIds.removeAll()
                        }
                    }

                    // Hide selected (active clusters)
                    if !selectedClusterIds.isEmpty {
                        actionButton(label: "Hide Selected", icon: "eye.slash", color: .gray) {
                            await runAction("Hiding...") {
                                for id in selectedClusterIds {
                                    try await service.ignoreCluster(clusterId: id)
                                }
                            }
                            selectedClusterIds.removeAll()
                        }
                    }

                    // Unhide selected (ignored clusters)
                    if !selectedIgnoredIds.isEmpty {
                        actionButton(label: "Unhide Selected", icon: "eye", color: .blue) {
                            await runAction("Restoring...") {
                                for id in selectedIgnoredIds {
                                    try await service.unignoreCluster(clusterId: id)
                                }
                            }
                            selectedIgnoredIds.removeAll()
                        }
                    }

                    Spacer()

                    // Show Ignored toggle
                    Button {
                        showIgnored.toggle()
                        selectedClusterIds.removeAll()
                        selectedIgnoredIds.removeAll()
                        Task { await loadData() }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: showIgnored ? "eye.slash.fill" : "eye.slash")
                                .font(.system(size: 11))
                            Text(showIgnored ? "Hide Ignored" : "Show Ignored")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(showIgnored ? .white : .secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(showIgnored ? Color.gray.opacity(0.6) : Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)

                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 20, height: 20)
                    }
                }

                // Status messages
                if !actionMessage.isEmpty {
                    Text(actionMessage)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if !errorMessage.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()

            // Content
            if clusters.isEmpty && ignoredClusters.isEmpty && !isLoading && !isDetecting {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "person.crop.rectangle.stack")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No Face Data Yet")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("Click \"Scan Faces\" to detect faces in indexed files.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if showIgnored {
                            // Ignored clusters only
                            if !ignoredClusters.isEmpty {
                                sectionHeader(title: "Ignored", count: ignoredClusters.count)

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 130, maximum: 160), spacing: 12)], spacing: 12) {
                                    ForEach(ignoredClusters) { cluster in
                                        IgnoredCard(
                                            cluster: cluster,
                                            isSelected: selectedIgnoredIds.contains(cluster.clusterId),
                                            onTap: { toggleIgnoredSelection(cluster.clusterId) }
                                        )
                                    }
                                }
                            } else {
                                VStack(spacing: 8) {
                                    Spacer()
                                    Text("No ignored clusters")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, minHeight: 200)
                            }
                        } else {
                            // Named people
                            if !namedClusters.isEmpty {
                                sectionHeader(title: "People", count: namedClusters.count)

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 130, maximum: 160), spacing: 12)], spacing: 12) {
                                    ForEach(namedClusters) { cluster in
                                        PersonCard(
                                            cluster: cluster,
                                            isSelected: selectedClusterIds.contains(cluster.clusterId),
                                            onTap: { toggleSelection(cluster.clusterId) },
                                            onRename: { name in
                                                Task {
                                                    await runAction("Renaming...") {
                                                        guard let personId = cluster.personId else { return }
                                                        try await service.renamePerson(personId: personId, name: name)
                                                    }
                                                }
                                            },
                                            onDelete: {
                                                Task {
                                                    await runAction("Removing name...") {
                                                        try await service.unnameCluster(clusterId: cluster.clusterId)
                                                    }
                                                }
                                            }
                                        )
                                    }
                                }
                            }

                            // Unnamed clusters
                            if !unnamedClusters.isEmpty {
                                sectionHeader(title: "Unnamed Clusters", count: unnamedClusters.count)

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 130, maximum: 160), spacing: 12)], spacing: 12) {
                                    ForEach(unnamedClusters) { cluster in
                                        ClusterCard(
                                            cluster: cluster,
                                            isSelected: selectedClusterIds.contains(cluster.clusterId),
                                            onTap: { toggleSelection(cluster.clusterId) },
                                            onName: { name in
                                                Task {
                                                    await runAction("Naming...") {
                                                        try await service.nameCluster(clusterId: cluster.clusterId, name: name)
                                                    }
                                                }
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .task {
            await loadData()
            await pollProgressOnce()
            if isDetecting {
                startProgressPolling()
            }
        }
        .onDisappear {
            progressPollTask?.cancel()
        }
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, count: Int) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            Text("(\(count))")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }

    private func statBadge(label: String, value: Int, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text("\(value)")
                .font(.system(size: 12, weight: .semibold))
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(6)
    }

    private func actionButton(label: String, icon: String, color: Color, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(label)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.8))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    private func toggleSelection(_ clusterId: Int) {
        if selectedClusterIds.contains(clusterId) {
            selectedClusterIds.remove(clusterId)
        } else {
            selectedClusterIds.insert(clusterId)
        }
    }

    private func toggleIgnoredSelection(_ clusterId: Int) {
        if selectedIgnoredIds.contains(clusterId) {
            selectedIgnoredIds.remove(clusterId)
        } else {
            selectedIgnoredIds.insert(clusterId)
        }
    }

    private func startProgressPolling() {
        progressPollTask?.cancel()
        progressPollTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                if Task.isCancelled { break }
                await pollProgressOnce()
                if detectProgress?.running != true {
                    await loadData()
                    break
                }
            }
        }
    }

    @MainActor
    private func pollProgressOnce() async {
        do {
            detectProgress = try await service.detectProgress()
        } catch {
            detectProgress = nil
        }
    }

    @MainActor
    private func loadData() async {
        isLoading = true
        errorMessage = ""
        do {
            async let statusResult = service.faceStatus()
            async let clustersResult = service.faceClusters()
            status = try await statusResult
            clusters = try await clustersResult

            if showIgnored {
                ignoredClusters = try await service.faceClusters(show: "ignored")
            } else {
                ignoredClusters = []
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    private func runAction(_ message: String, action: () async throws -> Void) async {
        isLoading = true
        actionMessage = message
        errorMessage = ""
        do {
            try await action()
            await loadData()
            if actionMessage == message {
                actionMessage = ""
            }
        } catch {
            errorMessage = error.localizedDescription
            actionMessage = ""
        }
        isLoading = false
    }
}
