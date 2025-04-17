import Foundation
import Combine

class BookCollectionViewModel: ObservableObject {
    // Published properties
    @Published var collections: [BookCollection] = []
    @Published var defaultCollections: [BookCollection] = []
    @Published var customCollections: [BookCollection] = []
    @Published var sharedCollections: [BookCollection] = []
    @Published var partnerSharedCollections: [BookCollection] = []
    @Published var selectedCollection: BookCollection?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Dependencies
    private let dataManager: DataManagerProtocol
    private var cancellables = Set<AnyCancellable>()
    private var userId: String
    private var username: String
    
    init(dataManager: DataManagerProtocol, userId: String, username: String) {
        self.dataManager = dataManager
        self.userId = userId
        self.username = username
        
        loadCollections()
    }
    
    // MARK: - Public Methods
    
    /// Load all collections from the data source
    func loadCollections() {
        isLoading = true
        errorMessage = nil
        
        dataManager.fetchBookCollections(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] collections in
                self?.collections = collections
                self?.categorizeCollections()
                
                // If no collections exist, create default ones
                if collections.isEmpty {
                    self?.createDefaultCollections()
                }
            }
            .store(in: &cancellables)
        
        loadPartnerSharedCollections()
    }
    
    /// Load collections shared by the partner
    func loadPartnerSharedCollections() {
        isLoading = true
        
        dataManager.fetchPartnerSharedCollections()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] collections in
                self?.partnerSharedCollections = collections
            }
            .store(in: &cancellables)
    }
    
    /// Create a new collection
    func createCollection(name: String, description: String?, isSharedWithPartner: Bool = false) {
        let newCollection = BookCollection(
            name: name,
            description: description,
            isSharedWithPartner: isSharedWithPartner,
            ownerId: userId,
            ownerUsername: username
        )
        
        saveCollection(newCollection)
    }
    
    /// Save a collection (create or update)
    func saveCollection(_ collection: BookCollection) {
        isLoading = true
        errorMessage = nil
        
        dataManager.saveBookCollection(collection)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] success in
                if success {
                    self?.loadCollections()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Delete a collection
    func deleteCollection(withId id: String) {
        isLoading = true
        errorMessage = nil
        
        dataManager.deleteBookCollection(id: id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] success in
                if success {
                    self?.loadCollections()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Add a book to the specified collection
    func addBookToCollection(book: Book, collectionId: String) {
        guard var collection = collections.first(where: { $0.id == collectionId }) else {
            return
        }
        
        collection.addBook(book)
        saveCollection(collection)
    }
    
    /// Remove a book from the specified collection
    func removeBookFromCollection(bookId: String, collectionId: String) {
        guard var collection = collections.first(where: { $0.id == collectionId }) else {
            return
        }
        
        collection.removeBook(withId: bookId)
        saveCollection(collection)
    }
    
    /// Update collection details
    func updateCollection(id: String, name: String? = nil, description: String? = nil) {
        guard var collection = collections.first(where: { $0.id == id }) else {
            return
        }
        
        if let name = name {
            collection.updateName(name)
        }
        
        if let description = description {
            collection.updateDescription(description)
        }
        
        saveCollection(collection)
    }
    
    /// Toggle sharing a collection with partner
    func toggleShareWithPartner(collectionId: String) {
        guard var collection = collections.first(where: { $0.id == collectionId }) else {
            return
        }
        
        collection.toggleSharedWithPartner()
        saveCollection(collection)
    }
    
    /// Set sort option for a collection
    func setSortOption(option: SortOption, collectionId: String) {
        guard var collection = collections.first(where: { $0.id == collectionId }) else {
            return
        }
        
        collection.setSortOption(option)
        saveCollection(collection)
    }
    
    /// Add filter option to a collection
    func addFilterOption(option: FilterOption, collectionId: String) {
        guard var collection = collections.first(where: { $0.id == collectionId }) else {
            return
        }
        
        collection.addFilterOption(option)
        saveCollection(collection)
    }
    
    /// Remove filter option from a collection
    func removeFilterOption(option: FilterOption, collectionId: String) {
        guard var collection = collections.first(where: { $0.id == collectionId }) else {
            return
        }
        
        collection.removeFilterOption(option)
        saveCollection(collection)
    }
    
    /// Clear all filter options from a collection
    func clearFilterOptions(collectionId: String) {
        guard var collection = collections.first(where: { $0.id == collectionId }) else {
            return
        }
        
        collection.clearFilterOptions()
        saveCollection(collection)
    }
    
    /// Get books processed according to the collection's sort and filter settings
    func processedBooks(forCollectionId id: String) -> [Book] {
        guard let collection = collections.first(where: { $0.id == id }) else {
            return []
        }
        
        return collection.processedBooks()
    }
    
    // MARK: - Private Methods
    
    /// Categorize collections into default, custom, and shared
    private func categorizeCollections() {
        defaultCollections = collections.filter { $0.isDefault }
        customCollections = collections.filter { !$0.isDefault && !$0.isSharedWithPartner }
        sharedCollections = collections.filter { $0.isSharedWithPartner }
    }
    
    /// Create default collections for a new user
    private func createDefaultCollections() {
        let defaultCollections = BookCollection.createDefaultCollections(
            ownerId: userId,
            ownerUsername: username
        )
        
        for collection in defaultCollections {
            saveCollection(collection)
        }
    }
    
    /// Get collection by ID
    func getCollection(id: String) -> BookCollection? {
        return collections.first(where: { $0.id == id })
    }
    
    /// Get the count of books in a collection
    func bookCount(inCollectionId id: String) -> Int {
        return getCollection(id: id)?.bookCount ?? 0
    }
    
    /// Get statistics for a collection
    func collectionStatistics(id: String) -> (bookCount: Int, totalPages: Int, avgRating: Double, completion: Double) {
        guard let collection = getCollection(id: id) else {
            return (0, 0, 0.0, 0.0)
        }
        
        return (
            collection.bookCount,
            collection.totalPages,
            collection.averageRating,
            collection.completionPercentage
        )
    }
    
    /// Check if a book is in a collection
    func isBookInCollection(bookId: String, collectionId: String) -> Bool {
        guard let collection = getCollection(id: collectionId) else {
            return false
        }
        
        return collection.books.contains(where: { $0.id == bookId })
    }
    
    /// Get collections that contain a specific book
    func collectionsContainingBook(bookId: String) -> [BookCollection] {
        return collections.filter { collection in
            collection.books.contains(where: { $0.id == bookId })
        }
    }
}

// Extension for previews
extension BookCollectionViewModel {
    static var preview: BookCollectionViewModel {
        let dataManager = PreviewDataManager()
        return BookCollectionViewModel(
            dataManager: dataManager,
            userId: "preview-user-id",
            username: "PreviewUser"
        )
    }
}

// Mock data manager for previews
private class PreviewDataManager: DataManagerProtocol {
    func fetchBookCollections(userId: String) -> AnyPublisher<[BookCollection], Error> {
        let sampleCollections = BookCollection.createDefaultCollections(
            ownerId: userId, 
            ownerUsername: "PreviewUser"
        )
        
        return Just(sampleCollections)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func fetchPartnerSharedCollections() -> AnyPublisher<[BookCollection], Error> {
        return Just([BookCollection]())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func fetchBookCollection(id: String) -> AnyPublisher<BookCollection, Error> {
        let collection = BookCollection(
            id: id,
            name: "Sample Collection",
            description: "A sample collection for preview",
            ownerId: "preview-user-id",
            ownerUsername: "PreviewUser"
        )
        
        return Just(collection)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func saveBookCollection(_ collection: BookCollection) -> AnyPublisher<Bool, Error> {
        return Just(true)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func deleteBookCollection(id: String) -> AnyPublisher<Bool, Error> {
        return Just(true)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func fetchBooks() -> AnyPublisher<[Book], Error> {
        let books = [
            Book(
                id: UUID().uuidString,
                title: "Sample Book 1",
                authors: ["Author One"],
                dateAdded: Date(),
                currentPage: 0,
                readingStatus: .notStarted
            ),
            Book(
                id: UUID().uuidString,
                title: "Sample Book 2",
                authors: ["Author Two"],
                dateAdded: Date(),
                currentPage: 50,
                readingStatus: .inProgress
            )
        ]
        
        return Just(books)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func fetchBook(id: String) -> AnyPublisher<Book, Error> {
        let book = Book(
            id: id,
            title: "Sample Book",
            authors: ["Sample Author"],
            dateAdded: Date(),
            currentPage: 0,
            readingStatus: .notStarted
        )
        
        return Just(book)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func fetchPartnerSharedBooks() -> AnyPublisher<[Book], Error> {
        return Just([Book]())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func saveBook(_ book: Book) -> AnyPublisher<Bool, Error> {
        return Just(true)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func deleteBook(id: String) -> AnyPublisher<Bool, Error> {
        return Just(true)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func updateReadingProgress(bookId: String, progress: ReadingProgress) -> AnyPublisher<Book, Error> {
        let book = Book(
            id: bookId,
            title: "Sample Book",
            authors: ["Sample Author"],
            dateAdded: Date(),
            currentPage: progress.currentPage,
            readingStatus: progress.readingStatus
        )
        
        return Just(book)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func shareBookWithPartner(bookId: String, shared: Bool) -> AnyPublisher<Bool, Error> {
        return Just(true)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func searchBooks(query: String) -> AnyPublisher<[Book], Error> {
        return Just([Book]())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func addNoteToBook(bookId: String, note: ReadingNote) -> AnyPublisher<Bool, Error> {
        return Just(true)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func deleteNote(bookId: String, noteId: String) -> AnyPublisher<Bool, Error> {
        return Just(true)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func saveReadingActivity(_ activity: ReadingActivity) -> AnyPublisher<Bool, Error> {
        return Just(true)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}

// Protocol for data manager to be implemented by the actual data service
protocol DataManagerProtocol {
    // Book Collection Methods
    func fetchBookCollections(userId: String) -> AnyPublisher<[BookCollection], Error>
    func fetchPartnerSharedCollections() -> AnyPublisher<[BookCollection], Error>
    func fetchBookCollection(id: String) -> AnyPublisher<BookCollection, Error> 
    func saveBookCollection(_ collection: BookCollection) -> AnyPublisher<Bool, Error>
    func deleteBookCollection(id: String) -> AnyPublisher<Bool, Error>
    
    // Book Methods
    func fetchBooks() -> AnyPublisher<[Book], Error>
    func fetchBook(id: String) -> AnyPublisher<Book, Error>
    func fetchPartnerSharedBooks() -> AnyPublisher<[Book], Error>
    func saveBook(_ book: Book) -> AnyPublisher<Bool, Error>
    func deleteBook(id: String) -> AnyPublisher<Bool, Error>
    func updateReadingProgress(bookId: String, progress: ReadingProgress) -> AnyPublisher<Book, Error>
    func shareBookWithPartner(bookId: String, shared: Bool) -> AnyPublisher<Bool, Error>
    func searchBooks(query: String) -> AnyPublisher<[Book], Error>
    
    // Note Methods
    func addNoteToBook(bookId: String, note: ReadingNote) -> AnyPublisher<Bool, Error>
    func deleteNote(bookId: String, noteId: String) -> AnyPublisher<Bool, Error>
    
    // Reading Activity Methods
    func saveReadingActivity(_ activity: ReadingActivity) -> AnyPublisher<Bool, Error>
} 