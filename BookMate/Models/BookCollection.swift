import Foundation

struct BookCollection: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var description: String?
    var books: [Book]
    var coverImages: [URL]?
    var createdDate: Date
    var lastModifiedDate: Date
    var isDefault: Bool
    var isSharedWithPartner: Bool
    var sortOption: SortOption
    var filterOptions: [FilterOption]
    
    var ownerId: String
    var ownerUsername: String
    
    static func == (lhs: BookCollection, rhs: BookCollection) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(id: String = UUID().uuidString,
         name: String,
         description: String? = nil,
         books: [Book] = [],
         coverImages: [URL]? = nil,
         createdDate: Date = Date(),
         lastModifiedDate: Date = Date(),
         isDefault: Bool = false,
         isSharedWithPartner: Bool = false,
         sortOption: SortOption = .title,
         filterOptions: [FilterOption] = [],
         ownerId: String,
         ownerUsername: String) {
        
        self.id = id
        self.name = name
        self.description = description
        self.books = books
        self.coverImages = coverImages
        self.createdDate = createdDate
        self.lastModifiedDate = lastModifiedDate
        self.isDefault = isDefault
        self.isSharedWithPartner = isSharedWithPartner
        self.sortOption = sortOption
        self.filterOptions = filterOptions
        self.ownerId = ownerId
        self.ownerUsername = ownerUsername
    }
    
    // Collection properties
    var bookCount: Int {
        return books.count
    }
    
    var totalPages: Int {
        return books.compactMap { $0.pageCount }.reduce(0, +)
    }
    
    var averageRating: Double {
        let ratedBooks = books.filter { $0.userRating != nil }
        if ratedBooks.isEmpty {
            return 0.0
        }
        
        let totalRating = ratedBooks.compactMap { $0.userRating }.reduce(0.0, +)
        return totalRating / Double(ratedBooks.count)
    }
    
    var completionPercentage: Double {
        let finishedBooks = books.filter { $0.readingStatus == .finished }
        if books.isEmpty {
            return 0.0
        }
        
        return Double(finishedBooks.count) / Double(books.count) * 100.0
    }
    
    var primaryGenres: [String] {
        var genreCounts: [String: Int] = [:]
        
        for book in books {
            if let categories = book.categories {
                for category in categories {
                    genreCounts[category, default: 0] += 1
                }
            }
        }
        
        // Return top 3 genres by count
        return genreCounts.sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
    }
    
    // Collection methods
    mutating func addBook(_ book: Book) {
        if !books.contains(where: { $0.id == book.id }) {
            books.append(book)
            updateLastModified()
        }
    }
    
    mutating func removeBook(withId id: String) {
        books.removeAll(where: { $0.id == id })
        updateLastModified()
    }
    
    mutating func updateName(_ newName: String) {
        name = newName
        updateLastModified()
    }
    
    mutating func updateDescription(_ newDescription: String?) {
        description = newDescription
        updateLastModified()
    }
    
    mutating func toggleSharedWithPartner() {
        isSharedWithPartner.toggle()
        updateLastModified()
    }
    
    mutating func setSortOption(_ option: SortOption) {
        sortOption = option
        updateLastModified()
    }
    
    mutating func addFilterOption(_ option: FilterOption) {
        if !filterOptions.contains(option) {
            filterOptions.append(option)
            updateLastModified()
        }
    }
    
    mutating func removeFilterOption(_ option: FilterOption) {
        filterOptions.removeAll(where: { $0 == option })
        updateLastModified()
    }
    
    mutating func clearFilterOptions() {
        filterOptions.removeAll()
        updateLastModified()
    }
    
    private mutating func updateLastModified() {
        lastModifiedDate = Date()
    }
    
    // Returns books sorted according to the collection's sort option
    func sortedBooks() -> [Book] {
        switch sortOption {
        case .title:
            return books.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .author:
            return books.sorted { 
                let author1 = $0.authors?.first ?? ""
                let author2 = $1.authors?.first ?? ""
                return author1.localizedCaseInsensitiveCompare(author2) == .orderedAscending
            }
        case .dateAdded:
            return books.sorted { $0.startedReading ?? Date.distantPast > $1.startedReading ?? Date.distantPast }
        case .publishedDate:
            return books.sorted { $0.publishedDate ?? Date.distantPast > $1.publishedDate ?? Date.distantPast }
        case .rating:
            return books.sorted { ($0.userRating ?? 0) > ($1.userRating ?? 0) }
        case .readingProgress:
            return books.sorted { $0.readingProgressPercentage > $1.readingProgressPercentage }
        }
    }
    
    // Returns books filtered according to the collection's filter options
    func filteredBooks() -> [Book] {
        if filterOptions.isEmpty {
            return books
        }
        
        return books.filter { book in
            // A book passes the filter if it satisfies at least one of the filter options
            return filterOptions.contains { filterOption in
                switch filterOption {
                case .readingStatus(let status):
                    return book.readingStatus == status
                case .genre(let genre):
                    return book.categories?.contains(genre) ?? false
                case .favorite:
                    return book.isFavorite
                case .hasNotes:
                    return !(book.userNotes?.isEmpty ?? true)
                case .unread:
                    return book.currentPage == 0
                case .inProgress:
                    return book.isCurrentlyReading
                case .completed:
                    return book.readingStatus == .finished
                }
            }
        }
    }
    
    // Returns sorted and filtered books
    func processedBooks() -> [Book] {
        return sortedBooks().filter { book in
            if filterOptions.isEmpty {
                return true
            }
            
            return filterOptions.contains { filterOption in
                switch filterOption {
                case .readingStatus(let status):
                    return book.readingStatus == status
                case .genre(let genre):
                    return book.categories?.contains(genre) ?? false
                case .favorite:
                    return book.isFavorite
                case .hasNotes:
                    return !(book.userNotes?.isEmpty ?? true)
                case .unread:
                    return book.currentPage == 0
                case .inProgress:
                    return book.isCurrentlyReading
                case .completed:
                    return book.readingStatus == .finished
                }
            }
        }
    }
    
    // Factory method for creating default collections
    static func createDefaultCollections(ownerId: String, ownerUsername: String) -> [BookCollection] {
        return [
            BookCollection(
                name: "All Books",
                description: "All of your books",
                isDefault: true,
                ownerId: ownerId,
                ownerUsername: ownerUsername
            ),
            BookCollection(
                name: "Currently Reading",
                description: "Books you're currently reading",
                isDefault: true,
                filterOptions: [.inProgress],
                ownerId: ownerId,
                ownerUsername: ownerUsername
            ),
            BookCollection(
                name: "Favorites",
                description: "Your favorite books",
                isDefault: true,
                filterOptions: [.favorite],
                ownerId: ownerId,
                ownerUsername: ownerUsername
            ),
            BookCollection(
                name: "To Read",
                description: "Books you want to read",
                isDefault: true,
                filterOptions: [.unread],
                ownerId: ownerId,
                ownerUsername: ownerUsername
            ),
            BookCollection(
                name: "Completed",
                description: "Books you've finished reading",
                isDefault: true,
                filterOptions: [.completed],
                ownerId: ownerId,
                ownerUsername: ownerUsername
            )
        ]
    }
}

enum SortOption: String, Codable, CaseIterable {
    case title = "title"
    case author = "author"
    case dateAdded = "date_added"
    case publishedDate = "published_date"
    case rating = "rating"
    case readingProgress = "reading_progress"
    
    var description: String {
        switch self {
        case .title:
            return "Title"
        case .author:
            return "Author"
        case .dateAdded:
            return "Date Added"
        case .publishedDate:
            return "Published Date"
        case .rating:
            return "Rating"
        case .readingProgress:
            return "Reading Progress"
        }
    }
}

enum FilterOption: Codable, Equatable, Hashable {
    case readingStatus(ReadingStatus)
    case genre(String)
    case favorite
    case hasNotes
    case unread
    case inProgress
    case completed
    
    var description: String {
        switch self {
        case .readingStatus(let status):
            return "Status: \(status.description)"
        case .genre(let genre):
            return "Genre: \(genre)"
        case .favorite:
            return "Favorites"
        case .hasNotes:
            return "Has Notes"
        case .unread:
            return "Unread"
        case .inProgress:
            return "In Progress"
        case .completed:
            return "Completed"
        }
    }
} 