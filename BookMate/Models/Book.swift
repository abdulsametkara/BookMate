import Foundation

// Reading status enumeration
enum ReadingStatus: String, Codable, CaseIterable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case onHold = "on_hold"
    case finished = "finished"
    case abandoned = "abandoned"
    
    var description: String {
        switch self {
        case .notStarted:
            return "Not Started"
        case .inProgress:
            return "In Progress"
        case .onHold:
            return "On Hold"
        case .finished:
            return "Finished"
        case .abandoned:
            return "Abandoned"
        }
    }
}

// Model for tracking reading progress
struct ReadingProgress: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var currentPage: Int
    var totalPages: Int
    var startedAt: Date?
    var lastReadAt: Date?
    var completedAt: Date?
    var readingStatus: ReadingStatus
    var minutesRead: Int
    
    var completionPercentage: Double {
        guard totalPages > 0 else { return 0 }
        return min(Double(currentPage) / Double(totalPages) * 100, 100.0)
    }
}

// Model for reading notes
struct ReadingNote: Identifiable, Codable, Equatable {
    var id: String
    var userId: String
    var bookId: String
    var page: Int?
    var content: String
    var createdAt: Date
    var updatedAt: Date?
    var isSharedWithPartner: Bool
    
    init(id: String = UUID().uuidString,
         userId: String,
         bookId: String,
         page: Int? = nil,
         content: String,
         createdAt: Date = Date(),
         updatedAt: Date? = nil,
         isSharedWithPartner: Bool = false) {
        
        self.id = id
        self.userId = userId
        self.bookId = bookId
        self.page = page
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isSharedWithPartner = isSharedWithPartner
    }
}

// Main Book model
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
    
    // User-specific properties
    var dateAdded: Date
    var startedReading: Date?
    var finishedReading: Date?
    var currentPage: Int
    var readingStatus: ReadingStatus
    var isFavorite: Bool
    var userRating: Double?
    var userNotes: String?
    var highlightedPassages: [HighlightedPassage]?
    var bookmarks: [Bookmark]?
    var readingTime: TimeInterval?
    var lastReadingSession: Date?
    
    // Reading sessions
    var readingSessions: [ReadingSession]?
    
    // Partner interaction properties
    var recommendedBy: String?
    var recommendedDate: Date?
    var sharedCollectionIds: [String]?
    var partnerNotes: String?
    
    static func == (lhs: Book, rhs: Book) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(id: String = UUID().uuidString,
         isbn: String? = nil,
         title: String,
         subtitle: String? = nil,
         authors: [String]? = nil,
         publisher: String? = nil,
         publishedDate: Date? = nil,
         description: String? = nil,
         pageCount: Int? = nil,
         categories: [String]? = nil,
         imageLinks: BookImageLinks? = nil,
         language: String? = nil,
         dateAdded: Date = Date(),
         startedReading: Date? = nil,
         finishedReading: Date? = nil,
         currentPage: Int = 0,
         readingStatus: ReadingStatus = .notStarted,
         isFavorite: Bool = false,
         userRating: Double? = nil,
         userNotes: String? = nil,
         highlightedPassages: [HighlightedPassage]? = nil,
         bookmarks: [Bookmark]? = nil,
         readingTime: TimeInterval? = nil,
         lastReadingSession: Date? = nil,
         readingSessions: [ReadingSession]? = nil,
         recommendedBy: String? = nil,
         recommendedDate: Date? = nil,
         sharedCollectionIds: [String]? = nil,
         partnerNotes: String? = nil) {
        
        self.id = id
        self.isbn = isbn
        self.title = title
        self.subtitle = subtitle
        self.authors = authors
        self.publisher = publisher
        self.publishedDate = publishedDate
        self.description = description
        self.pageCount = pageCount
        self.categories = categories
        self.imageLinks = imageLinks
        self.language = language
        
        self.dateAdded = dateAdded
        self.startedReading = startedReading
        self.finishedReading = finishedReading
        self.currentPage = currentPage
        self.readingStatus = readingStatus
        self.isFavorite = isFavorite
        self.userRating = userRating
        self.userNotes = userNotes
        self.highlightedPassages = highlightedPassages
        self.bookmarks = bookmarks
        self.readingTime = readingTime
        self.lastReadingSession = lastReadingSession
        
        self.readingSessions = readingSessions
        
        self.recommendedBy = recommendedBy
        self.recommendedDate = recommendedDate
        self.sharedCollectionIds = sharedCollectionIds
        self.partnerNotes = partnerNotes
    }
    
    // Derived properties
    var formattedAuthors: String {
        return authors?.joined(separator: ", ") ?? "Unknown Author"
    }
    
    var primaryCategory: String {
        return categories?.first ?? "Uncategorized"
    }
    
    var readingProgressPercentage: Double {
        guard let pageCount = pageCount, pageCount > 0 else {
            return 0.0
        }
        
        return Double(currentPage) / Double(pageCount) * 100.0
    }
    
    var isCurrentlyReading: Bool {
        return readingStatus == .inProgress
    }
    
    var coverImageUrl: URL? {
        return imageLinks?.thumbnail ?? imageLinks?.smallThumbnail
    }
    
    var hasCoverImage: Bool {
        return coverImageUrl != nil
    }
    
    var hasUserContent: Bool {
        return userNotes != nil || 
               (highlightedPassages?.isEmpty == false) || 
               (bookmarks?.isEmpty == false) ||
               userRating != nil
    }
    
    var isRecommended: Bool {
        return recommendedBy != nil
    }
    
    var totalReadingTimeFormatted: String {
        guard let time = readingTime else {
            return "No reading time recorded"
        }
        
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var averageReadingSpeed: Double? {
        guard let pageCount = pageCount, let readingTime = readingTime, readingTime > 0 else {
            return nil
        }
        
        // Pages per hour
        return Double(pageCount) / (readingTime / 3600)
    }
    
    // Mutating methods for user interactions
    mutating func updateReadingStatus(_ status: ReadingStatus) {
        readingStatus = status
        
        switch status {
        case .inProgress:
            if startedReading == nil {
                startedReading = Date()
            }
        case .finished:
            finishedReading = Date()
        case .notStarted:
            startedReading = nil
            finishedReading = nil
            currentPage = 0
        case .abandoned, .onHold:
            // No additional changes needed
            break
        }
    }
    
    mutating func updateCurrentPage(_ page: Int) {
        guard let pageCount = pageCount else {
            currentPage = page
            return
        }
        
        let validPage = min(max(0, page), pageCount)
        currentPage = validPage
        
        if validPage > 0 && readingStatus == .notStarted {
            updateReadingStatus(.inProgress)
        } else if validPage >= pageCount {
            updateReadingStatus(.finished)
        }
    }
    
    mutating func toggleFavorite() {
        isFavorite.toggle()
    }
    
    mutating func setRating(_ rating: Double?) {
        if let rating = rating {
            userRating = min(max(0, rating), 5)
        } else {
            userRating = nil
        }
    }
    
    mutating func updateNotes(_ notes: String?) {
        userNotes = notes
    }
    
    mutating func addHighlight(_ highlight: HighlightedPassage) {
        if highlightedPassages == nil {
            highlightedPassages = []
        }
        
        // Check for duplicates
        if !highlightedPassages!.contains(where: { $0.id == highlight.id }) {
            highlightedPassages!.append(highlight)
        }
    }
    
    mutating func removeHighlight(withId id: String) {
        highlightedPassages?.removeAll(where: { $0.id == id })
    }
    
    mutating func addBookmark(_ bookmark: Bookmark) {
        if bookmarks == nil {
            bookmarks = []
        }
        
        // Check for duplicates
        if !bookmarks!.contains(where: { $0.id == bookmark.id }) {
            bookmarks!.append(bookmark)
        }
    }
    
    mutating func removeBookmark(withId id: String) {
        bookmarks?.removeAll(where: { $0.id == id })
    }
    
    mutating func recordReadingSession(duration: TimeInterval, pagesRead: Int) {
        let session = ReadingSession(
            date: Date(), 
            duration: duration, 
            pagesRead: pagesRead, 
            startPage: currentPage - pagesRead,
            endPage: currentPage
        )
        
        if readingSessions == nil {
            readingSessions = []
        }
        
        readingSessions!.append(session)
        
        // Update total reading time
        if readingTime == nil {
            readingTime = 0
        }
        readingTime! += duration
        
        // Update last reading session date
        lastReadingSession = Date()
    }
    
    mutating func shareWithPartner(collectionId: String) {
        if sharedCollectionIds == nil {
            sharedCollectionIds = []
        }
        
        if !sharedCollectionIds!.contains(collectionId) {
            sharedCollectionIds!.append(collectionId)
        }
    }
    
    mutating func unshareWithPartner(collectionId: String) {
        sharedCollectionIds?.removeAll(where: { $0 == collectionId })
    }
    
    mutating func setPartnerNotes(_ notes: String?) {
        partnerNotes = notes
    }
    
    mutating func markAsRecommendedBy(partnerUsername: String) {
        recommendedBy = partnerUsername
        recommendedDate = Date()
    }
    
    // Factory method for creating a book from an API response
    static func fromGoogleBooksAPI(item: [String: Any]) -> Book? {
        guard let volumeInfo = item["volumeInfo"] as? [String: Any],
              let title = volumeInfo["title"] as? String,
              let id = item["id"] as? String else {
            return nil
        }
        
        let subtitle = volumeInfo["subtitle"] as? String
        let authors = volumeInfo["authors"] as? [String]
        let publisher = volumeInfo["publisher"] as? String
        
        let publishedDateString = volumeInfo["publishedDate"] as? String
        let publishedDate: Date?
        if let dateString = publishedDateString {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            publishedDate = dateFormatter.date(from: dateString)
        } else {
            publishedDate = nil
        }
        
        let description = volumeInfo["description"] as? String
        let pageCount = volumeInfo["pageCount"] as? Int
        let categories = volumeInfo["categories"] as? [String]
        let language = volumeInfo["language"] as? String
        
        var imageLinks: BookImageLinks?
        if let imageLinksDict = volumeInfo["imageLinks"] as? [String: Any] {
            let smallThumbnailString = imageLinksDict["smallThumbnail"] as? String
            let thumbnailString = imageLinksDict["thumbnail"] as? String
            
            let smallThumbnail = smallThumbnailString != nil ? URL(string: smallThumbnailString!) : nil
            let thumbnail = thumbnailString != nil ? URL(string: thumbnailString!) : nil
            
            imageLinks = BookImageLinks(smallThumbnail: smallThumbnail, thumbnail: thumbnail)
        }
        
        let isbnIdentifiers = volumeInfo["industryIdentifiers"] as? [[String: Any]]
        var isbn: String?
        
        if let identifiers = isbnIdentifiers {
            for identifier in identifiers {
                if let type = identifier["type"] as? String,
                   (type == "ISBN_13" || type == "ISBN_10"),
                   let value = identifier["identifier"] as? String {
                    isbn = value
                    break
                }
            }
        }
        
        return Book(
            id: id,
            isbn: isbn,
            title: title,
            subtitle: subtitle,
            authors: authors,
            publisher: publisher,
            publishedDate: publishedDate,
            description: description,
            pageCount: pageCount,
            categories: categories,
            imageLinks: imageLinks,
            language: language
        )
    }
}

struct BookImageLinks: Codable, Equatable {
    let smallThumbnail: URL?
    let thumbnail: URL?
}

struct HighlightedPassage: Identifiable, Codable, Equatable {
    let id: String
    let pageNumber: Int
    let passage: String
    let color: HighlightColor
    let note: String?
    let dateCreated: Date
    
    init(id: String = UUID().uuidString,
         pageNumber: Int,
         passage: String,
         color: HighlightColor = .yellow,
         note: String? = nil,
         dateCreated: Date = Date()) {
        
        self.id = id
        self.pageNumber = pageNumber
        self.passage = passage
        self.color = color
        self.note = note
        self.dateCreated = dateCreated
    }
}

enum HighlightColor: String, Codable, CaseIterable {
    case yellow = "yellow"
    case green = "green"
    case blue = "blue"
    case pink = "pink"
    case purple = "purple"
    
    var displayColor: String {
        return self.rawValue.capitalized
    }
}

struct Bookmark: Identifiable, Codable, Equatable {
    let id: String
    let pageNumber: Int
    let title: String?
    let note: String?
    let dateCreated: Date
    
    init(id: String = UUID().uuidString,
         pageNumber: Int,
         title: String? = nil,
         note: String? = nil,
         dateCreated: Date = Date()) {
        
        self.id = id
        self.pageNumber = pageNumber
        self.title = title
        self.note = note
        self.dateCreated = dateCreated
    }
}

struct ReadingSession: Identifiable, Codable, Equatable {
    let id: String
    let date: Date
    let duration: TimeInterval // in seconds
    let pagesRead: Int
    let startPage: Int
    let endPage: Int
    
    init(id: String = UUID().uuidString,
         date: Date,
         duration: TimeInterval,
         pagesRead: Int,
         startPage: Int,
         endPage: Int) {
        
        self.id = id
        self.date = date
        self.duration = duration
        self.pagesRead = pagesRead
        self.startPage = startPage
        self.endPage = endPage
    }
    
    var readingSpeed: Double? {
        if duration > 0 {
            // Pages per hour
            return Double(pagesRead) / (duration / 3600)
        }
        return nil
    }
}

struct BookNote: Identifiable, Codable, Equatable {
    let id: String
    let content: String
    let page: Int?
    let createdAt: Date
    let updatedAt: Date
    
    init(id: String = UUID().uuidString,
         content: String,
         page: Int? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        
        self.id = id
        self.content = content
        self.page = page
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct UserBook: Identifiable, Codable {
    var id: String
    var userId: String
    var bookId: String
    var status: ReadingStatus
    var currentPage: Int
    var startedAt: Date?
    var finishedAt: Date?
    var userRating: Int?
    var userNotes: String?
    var lastReadAt: Date?
    var isPartnerShared: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case bookId = "book_id"
        case status
        case currentPage = "current_page"
        case startedAt = "started_at"
        case finishedAt = "finished_at"
        case userRating = "user_rating"
        case userNotes = "user_notes"
        case lastReadAt = "last_read_at"
        case isPartnerShared = "is_partner_shared"
    }
}

// Örnek kitaplar
extension Book {
    static var samples: [Book] {
        [
            Book(
                title: "1984",
                authors: ["George Orwell"],
                description: "Büyük Birader sizi izliyor. Totaliter bir distopya romanı.",
                coverImageUrl: nil,
                publisher: nil,
                publishedDate: nil,
                pageCount: 328,
                isbn10: nil,
                isbn13: nil,
                categories: ["Distopya"],
                language: nil,
                currentPage: 0,
                startedReading: nil,
                finishedReading: nil,
                isCurrentlyReading: false,
                isFavorite: false,
                userNotes: [],
                userRating: 5.0
            ),
            Book(
                title: "Dönüşüm",
                authors: ["Franz Kafka"],
                description: "Gregor Samsa bir sabah kendini dev bir böceğe dönüşmüş olarak bulur.",
                coverImageUrl: nil,
                publisher: nil,
                publishedDate: nil,
                pageCount: 160,
                isbn10: nil,
                isbn13: nil,
                categories: ["Roman"],
                language: nil,
                currentPage: 0,
                startedReading: nil,
                finishedReading: nil,
                isCurrentlyReading: false,
                isFavorite: false,
                userNotes: [],
                userRating: 4.0
            ),
            Book(
                title: "Suç ve Ceza",
                authors: ["Fyodor Dostoyevski"],
                description: "Raskolnikov'un işlediği cinayet sonrası yaşadığı vicdani sorgulamaları anlatır.",
                coverImageUrl: nil,
                publisher: nil,
                publishedDate: nil,
                pageCount: 671,
                isbn10: nil,
                isbn13: nil,
                categories: ["Klasik"],
                language: nil,
                currentPage: 0,
                startedReading: nil,
                finishedReading: nil,
                isCurrentlyReading: false,
                isFavorite: false,
                userNotes: [],
                userRating: 3.5
            ),
            Book(
                title: "Simyacı",
                authors: ["Paulo Coelho"],
                description: "Santiago'nun kişisel efsanesini keşfetmek için çıktığı yolculuğu anlatır.",
                coverImageUrl: nil,
                publisher: nil,
                publishedDate: nil,
                pageCount: 184,
                isbn10: nil,
                isbn13: nil,
                categories: ["Roman"],
                language: nil,
                currentPage: 0,
                startedReading: nil,
                finishedReading: nil,
                isCurrentlyReading: false,
                isFavorite: false,
                userNotes: [],
                userRating: 4.5
            )
        ]
    }
} 