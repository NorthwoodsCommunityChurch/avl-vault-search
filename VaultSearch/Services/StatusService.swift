import Foundation

// MARK: - Models

struct GPUServerStatus: Identifiable {
    let id: Int
    let name: String
    let model: String
    let port: Int
    var isOnline: Bool = false
    var isProcessing: Bool = false
}

struct TypeCounts {
    var indexed: Int = 0
    var indexing: Int = 0
    var pending: Int = 0
    var error: Int = 0
    var offline: Int = 0

    var total: Int { indexed + indexing + pending + error + offline }
    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(indexed) / Double(total)
    }
}

struct IndexerCounts {
    var indexed: Int = 0
    var indexing: Int = 0
    var pending: Int = 0
    var error: Int = 0
    var offline: Int = 0
    var lastUpdated: Date?
    var byType: [String: TypeCounts] = [:]

    var total: Int { indexed + indexing + pending + error + offline }
    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(indexed) / Double(total)
    }
}

struct ScannerStatus {
    var state: String = "idle"          // "scanning" | "processing" | "sleeping" | "idle"
    var currentFolder: String = ""
    var filesScanned: Int = 0
    var filesNew: Int = 0
    var nextScanIn: Int? = nil
    var transcribing: Bool = false      // separate transcribe process is active
}

// MARK: - Decodable helpers

private struct GPUStatusResponse: Decodable {
    struct ServerStatus: Decodable {
        let id: Int
        let port: Int
        let online: Bool
        let processing: Bool
    }
    let servers: [ServerStatus]
}

private struct SlotResponse: Decodable {
    let isProcessing: Bool
    enum CodingKeys: String, CodingKey { case isProcessing = "is_processing" }
}

private struct StatusResponse: Decodable {
    let counts: Counts
    let scanner: ScannerRaw?
    struct Counts: Decodable {
        let pending: Int
        let indexing: Int
        let indexed: Int
        let error: Int
        let offline: Int
        let byType: [String: TypeStatusCounts]?
        enum CodingKeys: String, CodingKey {
            case pending, indexing, indexed, error, offline
            case byType = "by_type"
        }
    }
    struct TypeStatusCounts: Decodable {
        let pending: Int
        let indexing: Int
        let indexed: Int
        let error: Int
        let offline: Int
    }
    struct ScannerRaw: Decodable {
        let state: String
        let currentFolder: String?
        let filesScanned: Int
        let filesNew: Int
        let nextScanIn: Int?
        let transcribing: Bool?
        enum CodingKeys: String, CodingKey {
            case state
            case currentFolder = "current_folder"
            case filesScanned  = "files_scanned"
            case filesNew      = "files_new"
            case nextScanIn    = "next_scan_in"
            case transcribing
        }
    }
}

// MARK: - Service

@Observable
class StatusService {
    var servers: [GPUServerStatus] = [
        GPUServerStatus(id: 0, name: "RX 580 (Slot 3)", model: "Gemma 3 12B Q3_K_S",      port: 8090),
        GPUServerStatus(id: 1, name: "RX 580 (Slot 5)", model: "Gemma 3 12B Q3_K_S",      port: 8091),
        GPUServerStatus(id: 2, name: "Pro 580X (Slot 1)", model: "Whisper large-v3-turbo", port: 9090),
    ]
    var indexer = IndexerCounts()
    var scanner = ScannerStatus()
    var workerStatus: WorkerStatusResponse?

    private let host = "10.10.11.157"
    private let indexerPort = 8081
    private var pollTask: Task<Void, Never>?

    // Short-timeout session so the app doesn't hang on an offline server
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 8
        return URLSession(configuration: config)
    }()

    func startPolling() {
        stopPolling()
        pollTask = Task {
            while !Task.isCancelled {
                await fetchAll()
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    private func fetchAll() async {
        async let gpuResults = fetchGPUServers()
        async let indexerResult = fetchIndexer()
        async let workerResult = fetchWorkerStatus()
        var (gpus, counts, workers) = await (gpuResults, indexerResult, workerResult)

        // Port 8081 is the gate — if /status is unreachable, nothing on the server
        // is reachable from this Mac. Mark every GPU server offline regardless of
        // what fetchGPUServers returned (which may be stale cached values).
        if counts == nil {
            gpus = gpus.map { s in
                GPUServerStatus(id: s.id, name: s.name, model: s.model,
                                port: s.port, isOnline: false, isProcessing: false)
            }
        }

        // If the separate transcribe process is active, mark the Whisper server (9090) as Processing
        if let (_, scan) = counts, scan.transcribing {
            gpus = gpus.map { s in
                guard s.port == 9090 else { return s }
                return GPUServerStatus(id: s.id, name: s.name, model: s.model,
                                       port: s.port, isOnline: s.isOnline, isProcessing: true)
            }
        }

        await MainActor.run {
            self.servers = gpus
            if let (counts, scan) = counts {
                self.indexer = counts
                self.scanner = scan
            }
            // Keep last successful workerStatus on transient failures.
            // But if the server is fully offline (counts == nil), clear it.
            if workers != nil {
                self.workerStatus = workers
            } else if counts == nil {
                self.workerStatus = nil
            }
        }
    }

    // GPU servers bind to 127.0.0.1 — unreachable from the Mac.
    // The search API proxies their status via /gpu-status on port 8081.
    private func fetchGPUServers() async -> [GPUServerStatus] {
        guard let url = URL(string: "http://\(host):\(indexerPort)/gpu-status") else { return servers }
        do {
            let (data, resp) = try await session.data(from: url)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return servers }
            let decoded = try JSONDecoder().decode(GPUStatusResponse.self, from: data)
            return servers.map { s in
                guard let match = decoded.servers.first(where: { $0.id == s.id }) else { return s }
                return GPUServerStatus(id: s.id, name: s.name, model: s.model,
                                       port: s.port, isOnline: match.online, isProcessing: match.processing)
            }
        } catch { return servers }
    }

    private func fetchIndexer() async -> (IndexerCounts, ScannerStatus)? {
        guard let url = URL(string: "http://\(host):\(indexerPort)/status") else { return nil }
        do {
            let (data, resp) = try await session.data(from: url)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let decoded = try JSONDecoder().decode(StatusResponse.self, from: data)

            var byType: [String: TypeCounts] = [:]
            if let rawByType = decoded.counts.byType {
                for (key, val) in rawByType {
                    byType[key] = TypeCounts(
                        indexed:  val.indexed,
                        indexing: val.indexing,
                        pending:  val.pending,
                        error:    val.error,
                        offline:  val.offline
                    )
                }
            }

            let counts = IndexerCounts(
                indexed:  decoded.counts.indexed,
                indexing: decoded.counts.indexing,
                pending:  decoded.counts.pending,
                error:    decoded.counts.error,
                offline:  decoded.counts.offline,
                lastUpdated: Date(),
                byType: byType
            )

            var scan = ScannerStatus()
            if let s = decoded.scanner {
                scan = ScannerStatus(
                    state:         s.state,
                    currentFolder: s.currentFolder ?? "",
                    filesScanned:  s.filesScanned,
                    filesNew:      s.filesNew,
                    nextScanIn:    s.nextScanIn,
                    transcribing:  s.transcribing ?? false
                )
            }

            return (counts, scan)
        } catch { return nil }
    }

    private func fetchWorkerStatus() async -> WorkerStatusResponse? {
        guard let url = URL(string: "http://\(host):\(indexerPort)/worker-status") else { return nil }
        do {
            let (data, resp) = try await session.data(from: url)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            return try JSONDecoder().decode(WorkerStatusResponse.self, from: data)
        } catch { return nil }
    }
}
