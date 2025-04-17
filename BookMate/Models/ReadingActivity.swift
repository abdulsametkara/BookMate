import Foundation

struct ReadingActivity: Identifiable, Codable {
    var id: String
    var userId: String
    var userName: String
    var bookId: String
    var bookTitle: String
    var activityType: ActivityType
    var description: String
    var timestamp: String
    var date: Date
    
    enum ActivityType: String, Codable {
        case startedReading = "started_reading"
        case finishedReading = "finished_reading"
        case updatedProgress = "updated_progress"
        case addedNote = "added_note"
        case ratedBook = "rated_book"
        case addedBook = "added_book"
    }
    
    init(id: String = UUID().uuidString,
         userId: String,
         userName: String,
         bookId: String,
         bookTitle: String,
         activityType: ActivityType,
         description: String,
         date: Date = Date()) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.bookId = bookId
        self.bookTitle = bookTitle
        self.activityType = activityType
        self.description = description
        
        // Tarih formatı
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        self.timestamp = formatter.string(from: date)
        self.date = date
    }
}

// Örnek aktiviteler
extension ReadingActivity {
    static var samples: [ReadingActivity] {
        [
            ReadingActivity(
                userId: "partner1",
                userName: "Eş Kullanıcı",
                bookId: "book1",
                bookTitle: "1984",
                activityType: .updatedProgress,
                description: "1984 kitabında %75'e ulaştı.",
                date: Date().addingTimeInterval(-2 * 60 * 60)
            ),
            ReadingActivity(
                userId: "partner1",
                userName: "Eş Kullanıcı",
                bookId: "book2",
                bookTitle: "Dönüşüm",
                activityType: .finishedReading,
                description: "Dönüşüm kitabını tamamladı.",
                date: Date().addingTimeInterval(-2 * 24 * 60 * 60)
            ),
            ReadingActivity(
                userId: "partner1",
                userName: "Eş Kullanıcı",
                bookId: "book3",
                bookTitle: "Suç ve Ceza",
                activityType: .startedReading,
                description: "Suç ve Ceza kitabını okumaya başladı.",
                date: Date().addingTimeInterval(-5 * 24 * 60 * 60)
            ),
            ReadingActivity(
                userId: "partner1",
                userName: "Eş Kullanıcı",
                bookId: "book4",
                bookTitle: "Simyacı",
                activityType: .addedBook,
                description: "Simyacı kitabını kütüphanesine ekledi.",
                date: Date().addingTimeInterval(-10 * 24 * 60 * 60)
            )
        ]
    }
} 