import Foundation
import Combine

// Error types for book operations
enum BookServiceError: Error {
    case networkError
    case decodingError
    case notFound
    case authenticationError
    case serverError
    case unknownError
    
    var localizedDescription: String {
        switch self {
        case .networkError: return "Network connection error. Please check your internet connection."
        case .decodingError: return "Error processing data from server."
        case .notFound: return "The requested book couldn't be found."
        case .authenticationError: return "Authentication error. Please login again."
        case .serverError: return "Server error. Please try again later."
        case .unknownError: return "An unknown error occurred. Please try again."
        }
    }
}

// Protocol defining book service operations
protocol BookServiceProtocol {
    func fetchUserBooks() -> AnyPublisher<[Book], Error>
    func fetchPartnerSharedBooks() -> AnyPublisher<[Book], Error>
    func addBookToLibrary(book: Book) -> AnyPublisher<Bool, Error>
    func removeBookFromLibrary(bookId: String) -> AnyPublisher<Bool, Error>
    func updateReadingProgress(bookId: String, progress: ReadingProgress) -> AnyPublisher<Bool, Error>
    func shareBookWithPartner(bookId: String, shared: Bool) -> AnyPublisher<Bool, Error>
    func addNoteToBook(bookId: String, note: ReadingNote) -> AnyPublisher<Bool, Error>
    func deleteNote(bookId: String, noteId: String) -> AnyPublisher<Bool, Error>
    func searchBooks(query: String) -> AnyPublisher<[Book], Error>
    
    // Book Collections methods
    func fetchBookCollections(userId: String) -> AnyPublisher<[BookCollection], Error>
    func fetchPartnerSharedCollections() -> AnyPublisher<[BookCollection], Error>
    func saveBookCollection(_ collection: BookCollection) -> AnyPublisher<Bool, Error>
    func deleteBookCollection(id: String) -> AnyPublisher<Bool, Error>
    func addBookToCollection(bookId: String, collectionId: String) -> AnyPublisher<Bool, Error>
    func removeBookFromCollection(bookId: String, collectionId: String) -> AnyPublisher<Bool, Error>
}

// Implementation of BookService using CoreData and remote API
class BookService: BookServiceProtocol {
    private let dataManager: DataManagerProtocol
    private let networkService: NetworkServiceProtocol
    
    init(dataManager: DataManagerProtocol, networkService: NetworkServiceProtocol) {
        self.dataManager = dataManager
        self.networkService = networkService
    }
    
    func fetchUserBooks() -> AnyPublisher<[Book], Error> {
        return dataManager.fetchBooks()
            .eraseToAnyPublisher()
    }
    
    func fetchPartnerSharedBooks() -> AnyPublisher<[Book], Error> {
        return dataManager.fetchPartnerSharedBooks()
            .eraseToAnyPublisher()
    }
    
    func addBookToLibrary(book: Book) -> AnyPublisher<Bool, Error> {
        return dataManager.saveBook(book)
            .eraseToAnyPublisher()
    }
    
    func removeBookFromLibrary(bookId: String) -> AnyPublisher<Bool, Error> {
        return dataManager.deleteBook(id: bookId)
            .eraseToAnyPublisher()
    }
    
    func updateReadingProgress(bookId: String, progress: ReadingProgress) -> AnyPublisher<Bool, Error> {
        return dataManager.updateReadingProgress(bookId: bookId, progress: progress)
            .map { updatedBook -> Bool in
                // Create reading activity based on progress changes
                self.createReadingActivity(for: updatedBook)
                return true
            }
            .eraseToAnyPublisher()
    }
    
    func shareBookWithPartner(bookId: String, shared: Bool) -> AnyPublisher<Bool, Error> {
        return dataManager.shareBookWithPartner(bookId: bookId, shared: shared)
            .eraseToAnyPublisher()
    }
    
    func addNoteToBook(bookId: String, note: ReadingNote) -> AnyPublisher<Bool, Error> {
        return dataManager.addNoteToBook(bookId: bookId, note: note)
            .eraseToAnyPublisher()
    }
    
    func deleteNote(bookId: String, noteId: String) -> AnyPublisher<Bool, Error> {
        return dataManager.deleteNote(bookId: bookId, noteId: noteId)
            .eraseToAnyPublisher()
    }
    
    func searchBooks(query: String) -> AnyPublisher<[Book], Error> {
        // First search in local library
        let localSearch = dataManager.searchBooks(query: query)
        
        // Then search in remote API
        let remoteSearch = networkService.searchBooks(query: query)
            .catch { error -> AnyPublisher<[Book], Error> in
                print("Remote search failed: \(error.localizedDescription)")
                return Just([Book]())
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
        
        // Combine results, remove duplicates based on ISBN
        return Publishers.Merge(localSearch, remoteSearch)
            .collect()
            .map { results in
                let books = results.flatMap { $0 }
                var uniqueBooks = [Book]()
                var seenISBNs = Set<String>()
                
                for book in books {
                    if let isbn = book.isbn, !isbn.isEmpty {
                        if !seenISBNs.contains(isbn) {
                            seenISBNs.insert(isbn)
                            uniqueBooks.append(book)
                        }
                    } else {
                        uniqueBooks.append(book)
                    }
                }
                
                return uniqueBooks
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - Book Collections Methods
    
    func fetchBookCollections(userId: String) -> AnyPublisher<[BookCollection], Error> {
        return dataManager.fetchBookCollections(userId: userId)
            .eraseToAnyPublisher()
    }
    
    func fetchPartnerSharedCollections() -> AnyPublisher<[BookCollection], Error> {
        return dataManager.fetchPartnerSharedCollections()
            .eraseToAnyPublisher()
    }
    
    func saveBookCollection(_ collection: BookCollection) -> AnyPublisher<Bool, Error> {
        return dataManager.saveBookCollection(collection)
            .eraseToAnyPublisher()
    }
    
    func deleteBookCollection(id: String) -> AnyPublisher<Bool, Error> {
        return dataManager.deleteBookCollection(id: id)
            .eraseToAnyPublisher()
    }
    
    func addBookToCollection(bookId: String, collectionId: String) -> AnyPublisher<Bool, Error> {
        // First fetch the book
        return dataManager.fetchBook(id: bookId)
            .flatMap { [weak self] book -> AnyPublisher<BookCollection, Error> in
                guard let self = self else {
                    return Fail(error: BookServiceError.unknownError).eraseToAnyPublisher()
                }
                
                // Then fetch the collection
                return self.dataManager.fetchBookCollection(id: collectionId)
            }
            .flatMap { [weak self] collection -> AnyPublisher<Bool, Error> in
                guard let self = self else {
                    return Fail(error: BookServiceError.unknownError).eraseToAnyPublisher()
                }
                
                // Fetch book to add
                return self.dataManager.fetchBook(id: bookId)
                    .flatMap { book -> AnyPublisher<Bool, Error> in
                        var updatedCollection = collection
                        updatedCollection.addBook(book)
                        
                        // Save the updated collection
                        return self.dataManager.saveBookCollection(updatedCollection)
                    }
            }
            .eraseToAnyPublisher()
    }
    
    func removeBookFromCollection(bookId: String, collectionId: String) -> AnyPublisher<Bool, Error> {
        // Fetch the collection
        return dataManager.fetchBookCollection(id: collectionId)
            .flatMap { [weak self] collection -> AnyPublisher<Bool, Error> in
                guard let self = self else {
                    return Fail(error: BookServiceError.unknownError).eraseToAnyPublisher()
                }
                
                var updatedCollection = collection
                updatedCollection.removeBook(withId: bookId)
                
                // Save the updated collection
                return self.dataManager.saveBookCollection(updatedCollection)
            }
            .eraseToAnyPublisher()
    }
    
    // Helper method to create reading activity
    private func createReadingActivity(for book: Book) {
        guard let userId = UserDefaults.standard.string(forKey: "currentUserId"),
              let username = UserDefaults.standard.string(forKey: "currentUsername"),
              let progress = book.userProgress else {
            return
        }
        
        let activityType: ReadingActivityType
        let description: String
        
        switch progress.readingStatus {
        case .completed:
            activityType = .finishedReading
            description = "\(username) finished reading \(book.title)."
        case .inProgress:
            if progress.completionPercentage > 0 && progress.completionPercentage < 100 {
                activityType = .updatedProgress
                description = "\(username) reached \(Int(progress.completionPercentage))% in \(book.title)."
            } else {
                activityType = .startedReading
                description = "\(username) started reading \(book.title)."
            }
        case .notStarted:
            activityType = .addedToLibrary
            description = "\(username) added \(book.title) to their library."
        case .onHold:
            activityType = .pausedReading
            description = "\(username) paused reading \(book.title)."
        case .abandoned:
            activityType = .abandonedBook
            description = "\(username) abandoned reading \(book.title)."
        }
        
        let activity = ReadingActivity(
            userId: userId,
            username: username,
            bookId: book.id,
            bookTitle: book.title,
            coverImageUrl: book.coverImageUrl,
            activityType: activityType,
            description: description,
            timestamp: Date()
        )
        
        // Save the activity
        _ = dataManager.saveReadingActivity(activity)
    }
}

// Enumeration for reading activity types
enum ReadingActivityType: String, Codable {
    case startedReading
    case updatedProgress
    case finishedReading
    case addedToLibrary
    case pausedReading
    case abandonedBook
    case addedNote
    case sharedBook
}

// Reading activity model
struct ReadingActivity: Identifiable, Codable {
    let id: String
    let userId: String
    let username: String
    let bookId: String
    let bookTitle: String
    let coverImageUrl: URL?
    let activityType: ReadingActivityType
    let description: String
    let timestamp: Date
    
    init(id: String = UUID().uuidString,
         userId: String,
         username: String,
         bookId: String,
         bookTitle: String,
         coverImageUrl: URL? = nil,
         activityType: ReadingActivityType,
         description: String,
         timestamp: Date = Date()) {
        self.id = id
        self.userId = userId
        self.username = username
        self.bookId = bookId
        self.bookTitle = bookTitle
        self.coverImageUrl = coverImageUrl
        self.activityType = activityType
        self.description = description
        self.timestamp = timestamp
    }
} 