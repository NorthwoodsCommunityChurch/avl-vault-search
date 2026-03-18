import SwiftUI

struct FacePreviewPopover: View {
    let cluster: FaceCluster
    var onFaceRemoved: (() -> Void)? = nil

    @State private var allFaces: [FaceDetail] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var hoveredFaceId: String?

    private let service = SearchService()
    private let columns = [GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 10)]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Text(cluster.personName ?? "Unnamed Cluster")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(allFaces.count) faces")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            // Face grid
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView("Loading faces...")
                        .font(.system(size: 11))
                    Spacer()
                }
                .padding(.vertical, 20)
            } else if let error {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundColor(.red)
                    .padding(.vertical, 10)
            } else if allFaces.isEmpty {
                Text("No faces in this cluster")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(allFaces) { face in
                            ZStack(alignment: .topTrailing) {
                                AsyncImage(url: face.fullThumbnailURL) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    case .failure:
                                        Color(nsColor: .controlBackgroundColor)
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .foregroundColor(.secondary)
                                            )
                                    default:
                                        Color(nsColor: .controlBackgroundColor)
                                            .overlay(ProgressView().scaleEffect(0.5))
                                    }
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())

                                // Remove button on hover
                                if hoveredFaceId == face.id {
                                    Button {
                                        removeFace(face)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.white, .red)
                                    }
                                    .buttonStyle(.plain)
                                    .offset(x: 2, y: -2)
                                }
                            }
                            .onHover { hovering in
                                hoveredFaceId = hovering ? face.id : nil
                            }
                        }
                    }
                }
                .frame(minHeight: 450, maxHeight: 600)
            }

            if !allFaces.isEmpty {
                Text("Hover over a face and click X to remove it")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(width: 650, height: 550)
        .task {
            await loadAllFaces()
        }
    }

    private func loadAllFaces() async {
        isLoading = true
        error = nil
        do {
            let detail = try await service.getClusterFaces(clusterId: cluster.clusterId)
            allFaces = detail.faces
        } catch {
            self.error = "Failed to load faces"
            // Fallback to sample faces from cluster data
            allFaces = cluster.sampleFaces.map { sample in
                FaceDetail(
                    id: sample.faceId,
                    thumbnailUrl: sample.thumbnail,
                    hasThumbnail: true
                )
            }
        }
        isLoading = false
    }

    private func removeFace(_ face: FaceDetail) {
        Task {
            do {
                try await service.removeFace(faceId: face.id)
                allFaces.removeAll { $0.id == face.id }
                onFaceRemoved?()
            } catch {
                self.error = "Failed to remove face"
            }
        }
    }
}
