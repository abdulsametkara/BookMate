import Foundation

enum ReadingStatus: String, Codable, CaseIterable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case onHold = "on_hold"
    case finished = "finished"
    case abandoned = "abandoned"
}

struct Book: Identifiable, Codable, Equatable {
    let id: String
    let isbn: String?
    var title: String
    var subtitle: String?
    var authors: [String]?
    var publisher: String?
    var publishedDate: Date?
    var description: String?
    var pageCount: Int?
    var categories: [String]?
    var imageLinks: BookImageLinks?
    var language: String?
    
    // Kullanıcı özellikleri
    var dateAdded: Date
    var startedReading: Date?
    var finishedReading: Date?
    var currentPage: Int
    var readingStatus: ReadingStatus
    var isFavorite: Bool
    var userRating: Double?
    var userNotes: String?
    
    // Okuma bilgileri
    var readingTime: TimeInterval?
    var lastReadingSession: Date?
    
    // Partner bilgileri
    var recommendedBy: String?
    var recommendedDate: Date?
    var partnerNotes: String?
    
    // Hesaplanan özellikler
    var formattedAuthors: String {
        return authors?.joined(separator: ", ") ?? "Bilinmeyen Yazar"
    }
    
    var readingProgressPercentage: Double {
        guard let pageCount = pageCount, pageCount > 0 else {
            return 0.0
        }
        
        return min(Double(currentPage) / Double(pageCount) * 100.0, 100.0)
    }
    
    var isCompleted: Bool {
        return readingStatus == .finished
    }
    
    var isCurrentlyReading: Bool {
        return readingStatus == .inProgress
    }
    
    static func == (lhs: Book, rhs: Book) -> Bool {
        return lhs.id == rhs.id
    }
} 