import SwiftUI

struct FacePreviewPopover: View {
    let cluster: FaceCluster

    private let columns = [GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 8)]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(cluster.personName ?? "Unnamed Cluster")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(cluster.faceCount) faces")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            if cluster.allThumbnailURLs.isEmpty {
                Text("No face samples available")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(cluster.allThumbnailURLs, id: \.absoluteString) { url in
                        AsyncImage(url: url) { phase in
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
                    }
                }
            }
        }
        .padding(14)
        .frame(minWidth: 220, maxWidth: 320)
    }
}
