import SwiftUI

struct ClusterCard: View {
    let cluster: FaceCluster
    let isSelected: Bool
    let onTap: () -> Void
    let onName: (String) -> Void

    @State private var nameText = ""
    @State private var showingPreview = false

    var body: some View {
        VStack(spacing: 6) {
            // Face thumbnail — click to preview all sample faces
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
            .overlay(
                Circle()
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
            )
            .popover(isPresented: $showingPreview, arrowEdge: .bottom) {
                FacePreviewPopover(cluster: cluster)
            }

            // Name input
            HStack(spacing: 4) {
                TextField("Name", text: $nameText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .frame(maxWidth: 70)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
                    .cornerRadius(4)
                    .onSubmit {
                        let trimmed = nameText.trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty { onName(trimmed) }
                    }

                Button {
                    let trimmed = nameText.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty { onName(trimmed) }
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(nameText.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : .green)
                }
                .buttonStyle(.plain)
                .disabled(nameText.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            // Face count
            Text("\(cluster.faceCount) faces")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(width: 120, height: 140)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(isSelected ? 0.8 : 0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            if NSEvent.modifierFlags.contains(.shift) {
                onTap()  // Shift-click = toggle selection for merge
            } else {
                showingPreview = true  // Regular click = show face popover
            }
        }
    }
}
