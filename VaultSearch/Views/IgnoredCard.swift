import SwiftUI

struct IgnoredCard: View {
    let cluster: FaceCluster
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            // Face thumbnail (dimmed)
            AsyncImage(url: cluster.firstThumbnailURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Image(systemName: "person.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                default:
                    ProgressView()
                        .scaleEffect(0.6)
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            .opacity(0.5)
            .overlay(
                Circle()
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
            )

            // Name or cluster info
            Text(cluster.personName ?? "Cluster \(cluster.clusterId)")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(1)

            // Face count
            Text("\(cluster.faceCount) faces")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(width: 120, height: 120)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(isSelected ? 0.6 : 0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: isSelected ? 2 : 1)
        )
        .onTapGesture { onTap() }
    }
}
