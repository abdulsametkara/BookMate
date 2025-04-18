import Foundation

struct ReadingStatistics: Codable, Equatable {
    var totalBooksRead: Int
    var booksReadThisMonth: Int
    var booksReadThisYear: Int
    var totalPagesRead: Int
    var pagesReadThisMonth: Int
    var averageRating: Double
    var favoriteTopic: String
    var readingStreak: Int
    var longestStreak: Int
    
    init(totalBooksRead: Int = 0,
         booksReadThisMonth: Int = 0,
         booksReadThisYear: Int = 0,
         totalPagesRead: Int = 0,
         pagesReadThisMonth: Int = 0,
         averageRating: Double = 0.0,
         favoriteTopic: String = "",
         readingStreak: Int = 0,
         longestStreak: Int = 0) {
        
        self.totalBooksRead = totalBooksRead
        self.booksReadThisMonth = booksReadThisMonth
        self.booksReadThisYear = booksReadThisYear
        self.totalPagesRead = totalPagesRead
        self.pagesReadThisMonth = pagesReadThisMonth
        self.averageRating = averageRating
        self.favoriteTopic = favoriteTopic
        self.readingStreak = readingStreak
        self.longestStreak = longestStreak
    }
} 