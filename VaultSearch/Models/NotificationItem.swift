import Foundation

struct NotificationItem: Identifiable, Decodable {
    let id: Int
    let title: String
    let message: String
    let severity: String   // "info" | "warning" | "error"
    let createdAt: String
    let read: Bool

    enum CodingKeys: String, CodingKey {
        case id, title, message, severity, read
        case createdAt = "created_at"
    }
}

struct NotificationsResponse: Decodable {
    let notifications: [NotificationItem]
    let unreadCount: Int

    enum CodingKeys: String, CodingKey {
        case notifications
        case unreadCount = "unread_count"
    }
}
