import Foundation
import CoreData

struct User: Identifiable, Codable, Equatable {
    let id: String
    var username: String
    var email: String
    var profileImageUrl: URL?
    var bio: String?
    var joinDate: Date
    var lastActive: Date
    
    // Reading preferences and statistics
    var favoriteGenres: [String]
    var readingGoal: ReadingGoal?
    var statistics: ReadingStatistics
    
    // Social features
    var partnerId: String?
    var partnerUsername: String?
    var partnerProfileImageUrl: URL?
    var isPartnershipActive: Bool
    
    // Preferences
    var appTheme: AppTheme
    var notificationsEnabled: Bool
    var privacySettings: PrivacySettings
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(id: String = UUID().uuidString,
         username: String,
         email: String,
         profileImageUrl: URL? = nil,
         bio: String? = nil,
         joinDate: Date = Date(),
         lastActive: Date = Date(),
         favoriteGenres: [String] = [],
         readingGoal: ReadingGoal? = nil,
         statistics: ReadingStatistics = ReadingStatistics(),
         partnerId: String? = nil,
         partnerUsername: String? = nil,
         partnerProfileImageUrl: URL? = nil,
         isPartnershipActive: Bool = false,
         appTheme: AppTheme = .system,
         notificationsEnabled: Bool = true,
         privacySettings: PrivacySettings = PrivacySettings()) {
        
        self.id = id
        self.username = username
        self.email = email
        self.profileImageUrl = profileImageUrl
        self.bio = bio
        self.joinDate = joinDate
        self.lastActive = lastActive
        self.favoriteGenres = favoriteGenres
        self.readingGoal = readingGoal
        self.statistics = statistics
        self.partnerId = partnerId
        self.partnerUsername = partnerUsername
        self.partnerProfileImageUrl = partnerProfileImageUrl
        self.isPartnershipActive = isPartnershipActive
        self.appTheme = appTheme
        self.notificationsEnabled = notificationsEnabled
        self.privacySettings = privacySettings
    }
    
    // Derived properties
    var hasPartner: Bool {
        return partnerId != nil && isPartnershipActive
    }
    
    var formattedJoinDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: joinDate)
    }
    
    var isActiveReader: Bool {
        // User is considered active if they've been active in the last 7 days
        return Calendar.current.dateComponents([.day], from: lastActive, to: Date()).day ?? 0 < 7
    }
    
    // User methods
    mutating func updateProfile(username: String? = nil, bio: String? = nil, profileImageUrl: URL? = nil) {
        if let username = username {
            self.username = username
        }
        
        if let bio = bio {
            self.bio = bio
        }
        
        if let profileImageUrl = profileImageUrl {
            self.profileImageUrl = profileImageUrl
        }
    }
    
    mutating func connectWithPartner(partnerId: String, username: String, profileImageUrl: URL? = nil) {
        self.partnerId = partnerId
        self.partnerUsername = username
        self.partnerProfileImageUrl = profileImageUrl
        self.isPartnershipActive = true
    }
    
    mutating func disconnectFromPartner() {
        isPartnershipActive = false
    }
    
    mutating func updateReadingGoal(goal: ReadingGoal) {
        self.readingGoal = goal
    }
    
    mutating func addFavoriteGenre(genre: String) {
        if !favoriteGenres.contains(genre) {
            favoriteGenres.append(genre)
        }
    }
    
    mutating func removeFavoriteGenre(genre: String) {
        favoriteGenres.removeAll(where: { $0 == genre })
    }
    
    mutating func updateLastActive() {
        lastActive = Date()
    }
    
    mutating func updateTheme(theme: AppTheme) {
        appTheme = theme
    }
    
    mutating func toggleNotifications(enabled: Bool) {
        notificationsEnabled = enabled
    }
    
    mutating func updatePrivacySettings(settings: PrivacySettings) {
        privacySettings = settings
    }
}

struct UserStatistics: Codable {
    var totalBooksRead: Int = 0
    var totalPagesRead: Int = 0
    var totalReadingTimeMinutes: Int = 0
    var booksReadThisWeek: Int = 0
    var booksReadThisMonth: Int = 0
    var booksReadThisYear: Int = 0
    var pagesReadThisWeek: Int = 0
    var pagesReadThisMonth: Int = 0
    var pagesReadThisYear: Int = 0
    var readingTimeThisWeekMinutes: Int = 0
    var longestReadingStreakDays: Int = 0
    var currentReadingStreakDays: Int = 0
    var favoriteGenre: String = ""
    var averageDailyReadingTimeMinutes: Int = 0
}

struct UserPreferences: Codable, Equatable {
    var theme: AppTheme
    var notificationsEnabled: Bool
    var partnerActivityNotifications: Bool
    var dailyReminderTime: Date?
    var use24HourTime: Bool
    var defaultViewMode: LibraryViewMode
    
    init(theme: AppTheme = .system,
         notificationsEnabled: Bool = true,
         partnerActivityNotifications: Bool = true,
         dailyReminderTime: Date? = nil,
         use24HourTime: Bool = false,
         defaultViewMode: LibraryViewMode = .grid) {
        
        self.theme = theme
        self.notificationsEnabled = notificationsEnabled
        self.partnerActivityNotifications = partnerActivityNotifications
        self.dailyReminderTime = dailyReminderTime
        self.use24HourTime = use24HourTime
        self.defaultViewMode = defaultViewMode
    }
}

struct ReadingGoals: Codable, Equatable {
    var booksPerYear: Int
    var pagesPerDay: Int
    var minutesPerDay: Int
    var currentYearBooks: Int
    var currentDayPages: Int
    var currentDayMinutes: Int
    var lastUpdated: Date
    
    init(booksPerYear: Int = 12,
         pagesPerDay: Int = 20,
         minutesPerDay: Int = 30,
         currentYearBooks: Int = 0,
         currentDayPages: Int = 0,
         currentDayMinutes: Int = 0,
         lastUpdated: Date = Date()) {
        
        self.booksPerYear = booksPerYear
        self.pagesPerDay = pagesPerDay
        self.minutesPerDay = minutesPerDay
        self.currentYearBooks = currentYearBooks
        self.currentDayPages = currentDayPages
        self.currentDayMinutes = currentDayMinutes
        self.lastUpdated = lastUpdated
    }
}

struct ReadingStatistics: Codable, Equatable {
    var totalBooksRead: Int = 0
    var totalPagesRead: Int = 0
    var totalMinutesRead: Int = 0
    var booksReadThisMonth: Int = 0
    var booksReadThisYear: Int = 0
    var averageRating: Double = 0.0
    var favoriteGenre: String? = nil
    var readingStreak: Int = 0
    var longestReadingStreak: Int = 0
    var lastReadDate: Date? = nil
    
    mutating func updateAfterCompletingBook(book: Book, rating: Double?, readingTime: Int) {
        totalBooksRead += 1
        
        if let pages = book.pageCount {
            totalPagesRead += pages
        }
        
        totalMinutesRead += readingTime
        
        let currentDate = Date()
        let calendar = Calendar.current
        
        // Update monthly and yearly counts
        if calendar.isDate(currentDate, equalTo: currentDate, toGranularity: .month) {
            booksReadThisMonth += 1
        }
        
        if calendar.isDate(currentDate, equalTo: currentDate, toGranularity: .year) {
            booksReadThisYear += 1
        }
        
        // Update average rating
        if let rating = rating {
            let totalRatingPoints = averageRating * Double(totalBooksRead - 1)
            averageRating = (totalRatingPoints + rating) / Double(totalBooksRead)
        }
        
        // Update reading streak
        updateReadingStreak()
    }
    
    mutating func updateReadingStreak() {
        let currentDate = Date()
        let calendar = Calendar.current
        
        if let lastDate = lastReadDate {
            let daysSinceLastRead = calendar.dateComponents([.day], from: lastDate, to: currentDate).day ?? 0
            
            if daysSinceLastRead <= 1 {
                // Continue the streak
                readingStreak += 1
                longestReadingStreak = max(longestReadingStreak, readingStreak)
            } else if daysSinceLastRead > 1 {
                // Broke the streak
                readingStreak = 1
            }
        } else {
            // First time reading
            readingStreak = 1
            longestReadingStreak = 1
        }
        
        lastReadDate = currentDate
    }
    
    mutating func updateFavoriteGenre(books: [Book]) {
        var genreCounts: [String: Int] = [:]
        
        for book in books {
            if let categories = book.categories {
                for category in categories {
                    genreCounts[category, default: 0] += 1
                }
            }
        }
        
        favoriteGenre = genreCounts.max(by: { $0.value < $1.value })?.key
    }
}

enum AppTheme: String, Codable, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var description: String {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .system:
            return "System"
        }
    }
}

enum LibraryViewMode: String, Codable, CaseIterable {
    case list
    case grid
    case shelf3D
}

struct ReadingStats: Codable {
    var booksCompleted: Int
    var totalPagesRead: Int
    var readingStreak: Int
    var averageRating: Double?
    var fastestReadBook: String?
    var favoriteCategory: String?
    var readingGoal: Int?
    var weeklyReadingData: [DailyReading]?
    
    enum CodingKeys: String, CodingKey {
        case booksCompleted = "books_completed"
        case totalPagesRead = "total_pages_read"
        case readingStreak = "reading_streak"
        case averageRating = "average_rating"
        case fastestReadBook = "fastest_read_book"
        case favoriteCategory = "favorite_category"
        case readingGoal = "reading_goal"
        case weeklyReadingData = "weekly_reading_data"
    }
}

struct DailyReading: Codable {
    var date: Date
    var pagesRead: Int
    var minutesRead: Int
    
    enum CodingKeys: String, CodingKey {
        case date
        case pagesRead = "pages_read"
        case minutesRead = "minutes_read"
    }
}

struct Achievement: Identifiable, Codable {
    var id: String
    var title: String
    var description: String
    var icon: String
    var isUnlocked: Bool
    var unlockedDate: Date?
    
    init(id: String = UUID().uuidString,
         title: String,
         description: String,
         icon: String,
         isUnlocked: Bool = false,
         unlockedDate: Date? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.isUnlocked = isUnlocked
        self.unlockedDate = unlockedDate
    }
}

// Örnek başarılar
extension Achievement {
    static var defaultAchievements: [Achievement] {
        [
            Achievement(
                title: "İlk Kitap",
                description: "İlk kitabını tamamla",
                icon: "book",
                isUnlocked: true,
                unlockedDate: Date().addingTimeInterval(-60 * 24 * 60 * 60)
            ),
            Achievement(
                title: "Haftalık Okuyucu",
                description: "Bir hafta boyunca her gün oku",
                icon: "calendar",
                isUnlocked: false
            ),
            Achievement(
                title: "10 Kitap Kulübü",
                description: "10 kitap tamamla",
                icon: "books.vertical",
                isUnlocked: false
            ),
            Achievement(
                title: "Kitap Kurdu",
                description: "Tek bir günde 100 sayfa oku",
                icon: "speedometer",
                isUnlocked: false
            ),
            Achievement(
                title: "Keşifçi",
                description: "5 farklı türde kitap oku",
                icon: "map",
                isUnlocked: false
            ),
            Achievement(
                title: "Tam Kütüphane",
                description: "Kütüphanene 50 kitap ekle",
                icon: "books.vertical.fill",
                isUnlocked: false
            )
        ]
    }
}

// Örnek kullanıcı
extension User {
    static var sample: User {
        User(
            name: "Kullanıcı Adı",
            email: "user@example.com",
            statistics: UserStatistics(
                totalBooksRead: 5,
                totalPagesRead: 1240,
                totalReadingTimeMinutes: 1860,
                booksReadThisWeek: 1,
                booksReadThisMonth: 2,
                booksReadThisYear: 5,
                pagesReadThisWeek: 175,
                pagesReadThisMonth: 520,
                pagesReadThisYear: 1240,
                readingTimeThisWeekMinutes: 240,
                longestReadingStreakDays: 5,
                currentReadingStreakDays: 3,
                favoriteGenre: "Roman",
                averageDailyReadingTimeMinutes: 35
            ),
            achievements: Achievement.defaultAchievements
        )
    }
}

struct ReadingGoal: Codable, Equatable {
    var type: GoalType
    var target: Int
    var startDate: Date
    var endDate: Date
    var progress: Int
    
    var isCompleted: Bool {
        return progress >= target
    }
    
    var progressPercentage: Double {
        return min(Double(progress) / Double(target) * 100, 100)
    }
    
    var remainingDays: Int {
        return Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
    }
    
    init(type: GoalType = .books,
         target: Int,
         startDate: Date = Date(),
         endDate: Date,
         progress: Int = 0) {
        
        self.type = type
        self.target = target
        self.startDate = startDate
        self.endDate = endDate
        self.progress = progress
    }
}

enum GoalType: String, Codable, CaseIterable {
    case books = "books"
    case pages = "pages"
    case minutes = "minutes"
    
    var description: String {
        switch self {
        case .books:
            return "Books"
        case .pages:
            return "Pages"
        case .minutes:
            return "Minutes"
        }
    }
}

struct PrivacySettings: Codable, Equatable {
    var shareReadingActivity: Bool = true
    var shareRatings: Bool = true
    var shareNotes: Bool = false
    var profileVisibility: ProfileVisibility = .public
    
    enum ProfileVisibility: String, Codable, CaseIterable {
        case `public` = "public"
        case partnerOnly = "partner_only"
        case `private` = "private"
        
        var description: String {
            switch self {
            case .public:
                return "Public"
            case .partnerOnly:
                return "Partner Only"
            case .private:
                return "Private"
            }
        }
    }
} 