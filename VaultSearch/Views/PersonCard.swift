import SwiftUI

struct PersonCard: View {
    let cluster: FaceCluster
    let isSelected: Bool
    let onTap: () -> Void
    let onRename: (String) -> Void
    var onDelete: (() -> Void)? = nil

    @State private var showingPreview = false
    @State private var isEditing = false
    @State private var editText = ""
    @State private var showDeleteConfirm = false

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

            // Name — static with pencil button, or inline edit field
            if isEditing {
                HStack(spacing: 4) {
                    TextField("Name", text: $editText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                        .frame(maxWidth: 66)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
                        .cornerRadius(4)
                        .onSubmit { submitRename() }

                    Button { submitRename() } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(editText.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : .green)
                    }
                    .buttonStyle(.plain)
                    .disabled(editText.trimmingCharacters(in: .whitespaces).isEmpty)

                    Button { isEditing = false } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                HStack(spacing: 4) {
                    Text(cluster.personName ?? "Unknown")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Button {
                        editText = cluster.personName ?? ""
                        isEditing = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Face count
            Text("\(cluster.faceCount) faces")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(width: 120, height: 130)
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
        .contextMenu {
            Button {
                editText = cluster.personName ?? ""
                isEditing = true
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Delete Person", systemImage: "trash")
            }
        }
        .alert("Delete \(cluster.personName ?? "this person")?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete?()
            }
        } message: {
            Text("This removes the name. All \(cluster.faceCount) faces will go back to unnamed clusters.")
        }
    }

    private func submitRename() {
        let trimmed = editText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            onRename(trimmed)
            isEditing = false
        }
    }
}
