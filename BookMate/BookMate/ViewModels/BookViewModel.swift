import Foundation
import Combine

class BookViewModel: ObservableObject {
    @Published var allBooks: [Book] = []
    @Published var userLibrary: [Book] = []
    @Published var wishlistBooks: [Book] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    init() {
        loadBooks()
    }
    
    private func loadBooks() {
        // Örnek kitaplar
        allBooks = Book.samples
        userLibrary = allBooks
    }
    
    // MARK: - Computed Properties
    
    var currentlyReadingBook: Book? {
        userLibrary.first { $0.readingStatus == .inProgress }
    }
    
    var recentlyAddedBooks: [Book] {
        userLibrary.sorted { (book1: Book, book2: Book) -> Bool in
            return (book1.dateAdded ?? Date()) > (book2.dateAdded ?? Date())
        }.prefix(5).map { $0 }
    }
    
    var completedBooks: [Book] {
        userLibrary.filter { $0.readingStatus == .finished }
    }
    
    // MARK: - Wishlist Functions
    
    func addToWishlist(_ book: Book) {
        guard !isInWishlist(book) else { return }
        wishlistBooks.append(book)
    }
    
    func removeFromWishlist(_ book: Book) {
        wishlistBooks.removeAll { $0.id == book.id }
    }
    
    func isInWishlist(_ book: Book) -> Bool {
        wishlistBooks.contains { $0.id == book.id }
    }
    
    func addToLibrary(_ book: Book) {
        guard !userLibrary.contains(where: { $0.id == book.id }) else { return }
        userLibrary.append(book)
    }
    
    // MARK: - Book Management Functions
    
    func updateBookStatus(_ book: Book, status: ReadingStatus) {
        if let index = userLibrary.firstIndex(where: { $0.id == book.id }) {
            userLibrary[index].readingStatus = status
            
            // Update startedReading or finishedReading dates based on status
            if status == .inProgress && userLibrary[index].startedReading == nil {
                userLibrary[index].startedReading = Date()
            } else if status == .finished && userLibrary[index].finishedReading == nil {
                userLibrary[index].finishedReading = Date()
            }
        }
    }
    
    func updateCurrentPage(_ book: Book, page: Int) {
        if let index = userLibrary.firstIndex(where: { $0.id == book.id }) {
            userLibrary[index].currentPage = page
            userLibrary[index].lastReadAt = Date()
            
            // If book wasn't in progress, update status
            if userLibrary[index].readingStatus != .inProgress {
                userLibrary[index].readingStatus = .inProgress
                
                // Set startedReading if not already set
                if userLibrary[index].startedReading == nil {
                    userLibrary[index].startedReading = Date()
                }
            }
            
            // If current page equals page count, mark as finished
            if page >= (book.pageCount ?? 1) {
                userLibrary[index].readingStatus = .finished
                userLibrary[index].finishedReading = Date()
            }
        }
    }
} 