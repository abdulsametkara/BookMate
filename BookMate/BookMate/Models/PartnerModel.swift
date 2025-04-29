import Foundation

// Çift eşleştirme talebi modeli
struct PartnerRequest: Identifiable, Codable {
    var id: String // Talep gönderen kullanıcının ID'si
    var senderUsername: String
    var senderEmail: String
    var senderProfileImageURL: URL?
    var requestDate: Date
    var status: PartnerRequestStatus
    
    enum PartnerRequestStatus: String, Codable {
        case pending = "pending"
        case accepted = "accepted"
        case rejected = "rejected"
    }
}

// Eşleşmiş partner bilgisi 
struct Partner: Identifiable, Codable {
    var id: String // Partner kullanıcı ID'si
    var username: String
    var fullName: String?
    var profileImageURL: URL?
    var email: String
    var connectionDate: Date
    var lastActive: Date?
    var currentlyReading: CurrentlyReadingInfo?
    var statistics: PartnerStatistics
    
    struct CurrentlyReadingInfo: Codable {
        var bookId: String
        var bookTitle: String
        var bookCoverURL: URL?
        var progress: Double // 0-1 arası
        var lastReadDate: Date
    }
}

// Partner istatistikleri
struct PartnerStatistics: Codable {
    var booksRead: Int
    var pagesRead: Int
    var minutesRead: Int
    var currentStreak: Int // Kesintisiz okuma günleri
    var longestStreak: Int
    var favoriteGenres: [String: Int] // Genre adı ve kitap sayısı
    var readingGoal: ReadingGoal?
    var goalProgress: Double // 0-1 arası
    
    // Boş istatistikler oluşturmak için
    static func empty() -> PartnerStatistics {
        return PartnerStatistics(
            booksRead: 0,
            pagesRead: 0,
            minutesRead: 0,
            currentStreak: 0,
            longestStreak: 0,
            favoriteGenres: [:],
            readingGoal: nil,
            goalProgress: 0.0
        )
    }
}

// Partner aktivitesi
struct PartnerActivity: Identifiable, Codable {
    var id: String
    var partnerId: String
    var partnerUsername: String
    var activityType: ActivityType
    var timestamp: Date
    var bookInfo: BookInfo?
    var readingSession: ReadingSessionInfo?
    var goal: GoalInfo?
    var message: String?
    var isRead: Bool = false
    
    enum ActivityType: String, Codable {
        case startedReading = "startedReading"
        case finishedReading = "finishedReading"
        case addedBook = "addedBook"
        case achievedGoal = "achievedGoal"
        case setNewGoal = "setNewGoal"
        case reachedMilestone = "reachedMilestone"
        case streakUpdate = "streakUpdate"
        case message = "message"
    }
    
    struct BookInfo: Codable {
        var id: String
        var title: String
        var author: String
        var coverURL: URL?
    }
    
    struct ReadingSessionInfo: Codable {
        var duration: TimeInterval
        var pagesRead: Int?
        var progress: Double? // 0-1 arası
        var location: String?
    }
    
    struct GoalInfo: Codable {
        var type: ReadingGoalType
        var target: Int
        var progress: Double // 0-1 arası
    }
} 