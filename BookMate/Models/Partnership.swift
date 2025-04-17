import Foundation

struct Partnership: Identifiable, Codable {
    var id: String
    var userId: String
    var partnerId: String
    var status: PartnershipStatus
    var createdAt: Date
    var updatedAt: Date
    var lastActivityAt: Date?
    var sharedBookIds: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case partnerId = "partner_id"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastActivityAt = "last_activity_at"
        case sharedBookIds = "shared_book_ids"
    }
}

enum PartnershipStatus: String, Codable {
    case pending = "pending"
    case active = "active"
    case declined = "declined"
    case ended = "ended"
}

struct ActivityNotification: Identifiable, Codable {
    var id: String
    var userId: String
    var partnerId: String
    var activityType: ActivityType
    var bookId: String?
    var message: String
    var createdAt: Date
    var isRead: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case partnerId = "partner_id"
        case activityType = "activity_type"
        case bookId = "book_id"
        case message
        case createdAt = "created_at"
        case isRead = "is_read"
    }
}

enum ActivityType: String, Codable {
    case newBook = "new_book"
    case completedBook = "completed_book"
    case progressUpdate = "progress_update"
    case partnerRequest = "partner_request"
    case partnerAccepted = "partner_accepted"
    case bookShared = "book_shared"
    case ratingAdded = "rating_added"
    case noteAdded = "note_added"
} 