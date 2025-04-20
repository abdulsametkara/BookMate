import Foundation

struct User: Identifiable, Codable {
    var id: String
    var name: String
    var email: String
    var profileImageURL: URL?
    var partnerId: String?
    var partnerName: String?
    var dateJoined: Date
    var readingStats: ReadingStats
    var preferences: UserPreferences
    var achievements: [Achievement]
    
    // Firebase Auth UID ile kullanıcı oluşturmak için
    init(id: String, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
        self.dateJoined = Date()
        self.readingStats = ReadingStats()
        self.preferences = UserPreferences()
        self.achievements = []
    }
}

struct ReadingStats: Codable {
    var totalBooksRead: Int = 0
    var totalPagesRead: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var readingGoal: Int = 1 // Haftalık kitap hedefi
    var weeklyReadingTime: Int = 0 // Dakika cinsinden
    var lastReadDate: Date?
    
    // Bu hafta içinde okunması gereken kitap sayısı
    func weeklyProgress() -> Double {
        guard readingGoal > 0 else { return 0 }
        // Haftalık okuma ilerlemesi hesabı yapılacak
        // Şimdilik basit bir değer döndürüyoruz
        return Double(min(totalBooksRead, readingGoal)) / Double(readingGoal) * 100
    }
}

struct UserPreferences: Codable {
    var isDarkModeEnabled: Bool = false
    var notificationsEnabled: Bool = true
    var dailyReminderTime: Date?
    var shareReadingStatus: Bool = true
    var defaultBookSortOrder: BookSortOrder = .dateAdded
    var customThemeColor: String?
}

struct Achievement: Identifiable, Codable {
    var id: String
    var title: String
    var description: String
    var iconName: String
    var dateEarned: Date
    var isShared: Bool = false
} 