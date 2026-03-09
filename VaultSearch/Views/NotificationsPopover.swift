import SwiftUI

struct NotificationsPopover: View {
    let service: NotificationService

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Notifications")
                    .font(.headline)
                Spacer()
                if service.unreadCount > 0 {
                    Button("Mark all read") {
                        Task { await service.markAllRead() }
                    }
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Divider()

            if service.notifications.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                    Text("No notifications")
                        .foregroundColor(.secondary)
                        .font(.callout)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(service.notifications) { notif in
                            NotificationRow(item: notif)
                            Divider()
                        }
                    }
                }
            }
        }
        .frame(width: 360, height: 340)
    }
}

struct NotificationRow: View {
    let item: NotificationItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: severityIcon)
                .foregroundColor(severityColor)
                .font(.system(size: 15))
                .frame(width: 18)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 12, weight: item.read ? .regular : .semibold))
                Text(item.message)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                Text(formattedDate)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.7))
            }

            Spacer()

            if !item.read {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 7, height: 7)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(item.read ? Color.clear : Color.accentColor.opacity(0.05))
    }

    private var severityIcon: String {
        switch item.severity {
        case "error":   return "xmark.circle.fill"
        case "warning": return "exclamationmark.triangle.fill"
        default:        return "info.circle.fill"
        }
    }

    private var severityColor: Color {
        switch item.severity {
        case "error":   return .red
        case "warning": return .orange
        default:        return .blue
        }
    }

    private var formattedDate: String {
        let raw = item.createdAt
        let fmts = ["yyyy-MM-dd'T'HH:mm:ss.SSSSSS", "yyyy-MM-dd'T'HH:mm:ss"]
        let out = DateFormatter()
        out.dateFormat = "MMM d, h:mm a"
        for fmt in fmts {
            let df = DateFormatter()
            df.dateFormat = fmt
            if let date = df.date(from: raw) {
                return out.string(from: date)
            }
        }
        return raw
    }
}
