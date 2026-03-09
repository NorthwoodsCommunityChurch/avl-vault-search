import Foundation

@Observable
class NotificationService {
    var notifications: [NotificationItem] = []
    var unreadCount: Int = 0

    private let host = "10.10.11.157"
    private let port = 8081
    private var pollTask: Task<Void, Never>?

    func startPolling() {
        stopPolling()
        pollTask = Task {
            while !Task.isCancelled {
                await fetchNotifications()
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    func fetchNotifications() async {
        guard let url = URL(string: "http://\(host):\(port)/notifications") else { return }
        do {
            let (data, resp) = try await URLSession.shared.data(from: url)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return }
            let decoded = try JSONDecoder().decode(NotificationsResponse.self, from: data)
            await MainActor.run {
                self.notifications = decoded.notifications
                self.unreadCount = decoded.unreadCount
            }
        } catch {}
    }

    func markAllRead() async {
        guard let url = URL(string: "http://\(host):\(port)/notifications/mark-read") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = Data("{}".utf8)
        do {
            _ = try await URLSession.shared.data(for: req)
            await MainActor.run {
                self.unreadCount = 0
                self.notifications = self.notifications.map { n in
                    NotificationItem(id: n.id, title: n.title, message: n.message,
                                     severity: n.severity, createdAt: n.createdAt, read: true)
                }
            }
        } catch {}
    }
}
