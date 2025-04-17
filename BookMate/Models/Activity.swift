import Foundation

struct Activity: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let username: String
    let userProfileImageUrl: URL?
    let type: ActivityType
    let bookId: String?
    let bookTitle: String?
    let bookCoverImageUrl: URL?
    let pageNumber: Int?
    let completedPercentage: Double?
    let rating: Double?
    let noteId: String?
    let noteContent: String?
    let timestamp: Date
    var isVisible: Bool
    
    static func == (lhs: Activity, rhs: Activity) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(id: String = UUID().uuidString,
         userId: String,
         username: String,
         userProfileImageUrl: URL? = nil,
         type: ActivityType,
         bookId: String? = nil,
         bookTitle: String? = nil,
         bookCoverImageUrl: URL? = nil,
         pageNumber: Int? = nil,
         completedPercentage: Double? = nil,
         rating: Double? = nil,
         noteId: String? = nil,
         noteContent: String? = nil,
         timestamp: Date = Date(),
         isVisible: Bool = true) {
        
        self.id = id
        self.userId = userId
        self.username = username
        self.userProfileImageUrl = userProfileImageUrl
        self.type = type
        self.bookId = bookId
        self.bookTitle = bookTitle
        self.bookCoverImageUrl = bookCoverImageUrl
        self.pageNumber = pageNumber
        self.completedPercentage = completedPercentage
        self.rating = rating
        self.noteId = noteId
        self.noteContent = noteContent
        self.timestamp = timestamp
        self.isVisible = isVisible
    }
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        return formatter.string(from: timestamp)
    }
    
    var activityDescription: String {
        switch type {
        case .startedReading:
            return "started reading \(bookTitle ?? "a book")"
        case .finishedReading:
            return "finished reading \(bookTitle ?? "a book")"
        case .updatedProgress:
            if let percentage = completedPercentage {
                return "updated progress to \(Int(percentage))% in \(bookTitle ?? "a book")"
            } else if let page = pageNumber {
                return "read to page \(page) in \(bookTitle ?? "a book")"
            } else {
                return "updated progress in \(bookTitle ?? "a book")"
            }
        case .addedBook:
            return "added \(bookTitle ?? "a new book") to their library"
        case .ratedBook:
            if let rating = rating {
                return "rated \(bookTitle ?? "a book") \(rating)/5"
            } else {
                return "rated \(bookTitle ?? "a book")"
            }
        case .addedNote:
            return "added a note to \(bookTitle ?? "a book")"
        case .achievedGoal:
            return "reached a reading goal"
        case .joinedApp:
            return "joined BookMate"
        case .connectedWithPartner:
            return "connected with their reading partner"
        }
    }
}

enum ActivityType: String, Codable, CaseIterable {
    case startedReading = "started_reading"
    case finishedReading = "finished_reading"
    case updatedProgress = "updated_progress"
    case addedBook = "added_book"
    case ratedBook = "rated_book"
    case addedNote = "added_note"
    case achievedGoal = "achieved_goal"
    case joinedApp = "joined_app"
    case connectedWithPartner = "connected_with_partner"
} 