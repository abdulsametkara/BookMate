import Foundation

struct Couple: Identifiable, Codable {
    var id: String
    var user1Id: String
    var user2Id: String
    var createdDate: Date
    var sharedBooks: [String] // Paylaşılan kitapların ID'leri
    var sharedReadingGoals: [SharedReadingGoal]
    var milestones: [CoupleMilestone]
    var couplesBookshelf: [String] // Çiftin ortak kitaplığındaki kitapların ID'leri
    
    init(user1Id: String, user2Id: String) {
        self.id = UUID().uuidString
        self.user1Id = user1Id
        self.user2Id = user2Id
        self.createdDate = Date()
        self.sharedBooks = []
        self.sharedReadingGoals = []
        self.milestones = []
        self.couplesBookshelf = []
    }
}

struct SharedReadingGoal: Identifiable, Codable {
    var id: String
    var title: String
    var description: String
    var targetDate: Date
    var isCompleted: Bool
    var booksToRead: [String] // Hedef kitapların ID'leri
    var createdBy: String // Kullanıcı ID'si
    var dateCreated: Date
    
    init(title: String, description: String, targetDate: Date, booksToRead: [String], createdBy: String) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.targetDate = targetDate
        self.isCompleted = false
        self.booksToRead = booksToRead
        self.createdBy = createdBy
        self.dateCreated = Date()
    }
}

struct CoupleMilestone: Identifiable, Codable {
    var id: String
    var title: String
    var description: String
    var dateAchieved: Date
    var type: MilestoneType
    
    enum MilestoneType: String, Codable {
        case booksRead = "Okunan Kitaplar"
        case readingStreak = "Okuma Serisi"
        case relationship = "İlişki"
        case custom = "Özel"
    }
}

// Bir kitabın çift tarafından paylaşılmasıyla ilgili bilgiler
struct SharedBookDetails: Codable {
    var bookId: String
    var sharedBy: String // Paylaşan kullanıcının ID'si
    var dateShared: Date
    var notes: String?
    var isAccepted: Bool
    var isCompleted: Bool
    var user1Progress: Double
    var user2Progress: Double
} 