import Foundation

// MARK: - Worker Status Response

struct WorkerStatusResponse: Decodable {
    let gpus: [GPUWorkerInfo]
    let cpuWorkers: CPUWorkersInfo
    let crawler: CrawlerInfo

    enum CodingKeys: String, CodingKey {
        case gpus
        case cpuWorkers = "cpu_workers"
        case crawler
    }
}

struct GPUWorkerInfo: Decodable, Identifiable {
    let name: String
    let port: Int
    let model: String
    let online: Bool
    let processing: Bool
    let currentTask: CurrentTaskInfo?
    let queue: QueueCounts
    let orchestratorState: String?  // Pro 580X only: "gemma_ready", "whisper_busy", etc.

    var id: String { "\(name)-\(port)" }

    var isOrchestrated: Bool { orchestratorState != nil }

    enum CodingKeys: String, CodingKey {
        case name, port, model, online, processing
        case currentTask = "current_task"
        case queue
        case orchestratorState = "orchestrator_state"
    }
}

struct CurrentTaskInfo: Decodable {
    let source: String
    let file: String
    let taskType: String

    var isAPI: Bool { source == "api" }

    enum CodingKeys: String, CodingKey {
        case source, file
        case taskType = "task_type"
    }
}

struct QueueCounts: Decodable {
    let api: Int
    let crawler: Int

    var total: Int { api + crawler }
}

struct CPUWorkersInfo: Decodable {
    let faceDetect: FaceDetectWorkerInfo
    let sceneDetect: SceneDetectWorkerInfo
    let ala: ALAWorkerInfo?

    enum CodingKeys: String, CodingKey {
        case faceDetect = "face_detect"
        case sceneDetect = "scene_detect"
        case ala
    }
}

struct ALAWorkerInfo: Decodable {
    let processing: Bool
    let currentTask: CurrentTaskInfo?
    let queue: QueueCounts

    enum CodingKeys: String, CodingKey {
        case processing
        case currentTask = "current_task"
        case queue
    }
}

struct FaceDetectWorkerInfo: Decodable {
    let processing: Bool
    let currentTask: CurrentTaskInfo?
    let queue: QueueCounts

    enum CodingKeys: String, CodingKey {
        case processing
        case currentTask = "current_task"
        case queue
    }
}

struct SceneDetectWorkerInfo: Decodable {
    let workers: Int
    let active: Int
    let queue: QueueCounts
}

struct CrawlerInfo: Decodable {
    let state: String
    let currentFolder: String

    enum CodingKeys: String, CodingKey {
        case state
        case currentFolder = "current_folder"
    }
}
