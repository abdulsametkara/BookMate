import Foundation
import Combine

class BookViewModel: ObservableObject {
    // Published properties
    @Published var books: [Book] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedBook: Book?
    @Published var recentlyAddedBooks: [Book] = []
    @Published var currentlyReadingBooks: [Book] = []
    @Published var userLibrary: [Book] = []
    @Published var partnerSharedBooks: [Book] = []
    @Published var recommendedBooks: [Book] = []
    @Published var searchResults: [Book] = []
    
    // Services would be injected through dependency injection
    private let bookService: BookServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(bookService: BookServiceProtocol = BookService()) {
        self.bookService = bookService
        loadSampleBooks() // For development only
    }
    
    // MARK: - Public Methods
    
    func fetchUserLibrary() {
        isLoading = true
        errorMessage = nil
        
        bookService.fetchUserBooks()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] books in
                self?.books = books
                self?.userLibrary = books
                self?.updateBookCollections()
            }
            .store(in: &cancellables)
    }
    
    func fetchPartnerSharedBooks() {
        isLoading = true
        errorMessage = nil
        
        bookService.fetchPartnerSharedBooks()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] books in
                self?.partnerSharedBooks = books
            }
            .store(in: &cancellables)
    }
    
    func searchBooks(query: String) {
        guard !query.isEmpty else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        bookService.searchBooks(query: query)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] books in
                self?.books = books
            }
            .store(in: &cancellables)
    }
    
    func addBookToLibrary(_ book: Book) {
        isLoading = true
        errorMessage = nil
        
        bookService.addBookToLibrary(book)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] updatedBook in
                self?.addBookToUserLibrary(updatedBook)
            }
            .store(in: &cancellables)
    }
    
    func updateReadingProgress(for book: Book, progress: ReadingProgress) {
        isLoading = true
        errorMessage = nil
        
        bookService.updateReadingProgress(bookId: book.id, progress: progress)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] updatedBook in
                self?.updateBook(updatedBook)
            }
            .store(in: &cancellables)
    }
    
    func shareBookWithPartner(_ book: Book) {
        isLoading = true
        errorMessage = nil
        
        bookService.shareBookWithPartner(bookId: book.id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] updatedBook in
                self?.updateBook(updatedBook)
            }
            .store(in: &cancellables)
    }
    
    func addNote(to book: Book, note: ReadingNote) {
        isLoading = true
        errorMessage = nil
        
        bookService.addNoteToBook(bookId: book.id, note: note)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] updatedBook in
                self?.updateBook(updatedBook)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    
    private func updateBookCollections() {
        // Get recently added books (last 5)
        recentlyAddedBooks = Array(userLibrary
            .sorted(by: { $0.addedToLibraryAt > $1.addedToLibraryAt })
            .prefix(5))
        
        // Get currently reading books
        currentlyReadingBooks = userLibrary.filter { book in
            if let progress = book.userProgress {
                return progress.readingStatus == .inProgress
            }
            return false
        }
    }
    
    private func addBookToUserLibrary(_ book: Book) {
        if let index = userLibrary.firstIndex(where: { $0.id == book.id }) {
            userLibrary[index] = book
        } else {
            userLibrary.append(book)
        }
        updateBookCollections()
    }
    
    private func updateBook(_ updatedBook: Book) {
        if let index = userLibrary.firstIndex(where: { $0.id == updatedBook.id }) {
            userLibrary[index] = updatedBook
        }
        
        if let index = partnerSharedBooks.firstIndex(where: { $0.id == updatedBook.id }) {
            partnerSharedBooks[index] = updatedBook
        }
        
        if let index = books.firstIndex(where: { $0.id == updatedBook.id }) {
            books[index] = updatedBook
        }
        
        updateBookCollections()
    }
    
    // This is for development/testing only
    private func loadSampleBooks() {
        let sampleBooks = [
            Book(
                id: UUID().uuidString,
                title: "1984",
                authors: ["George Orwell"],
                coverImageUrl: nil,
                description: "Büyük Birader sizi izliyor. Totaliter bir distopya romanı.",
                isbn: "978-0451524935",
                pageCount: 328,
                publishedDate: nil,
                publisher: "Signet Classic",
                categories: ["Distopya", "Klasik"],
                language: "en",
                userProgress: ReadingProgress(
                    currentPage: 156,
                    totalPages: 328,
                    startedAt: Date().addingTimeInterval(-30*24*60*60), // 30 days ago
                    lastReadAt: Date().addingTimeInterval(-2*24*60*60), // 2 days ago
                    completedAt: nil,
                    readingStatus: .inProgress,
                    minutesRead: 340
                ),
                rating: 4.5,
                notes: [
                    ReadingNote(
                        id: UUID().uuidString,
                        userId: "current-user-id",
                        bookId: UUID().uuidString,
                        page: 42,
                        content: "Big Brother kavramı günümüzde de çok geçerli.",
                        createdAt: Date().addingTimeInterval(-15*24*60*60),
                        updatedAt: nil,
                        isSharedWithPartner: true
                    )
                ],
                isSharedWithPartner: true,
                addedToLibraryAt: Date().addingTimeInterval(-45*24*60*60)
            ),
            Book(
                id: UUID().uuidString,
                title: "Dönüşüm",
                authors: ["Franz Kafka"],
                coverImageUrl: nil,
                description: "Gregor Samsa bir sabah kendini dev bir böceğe dönüşmüş olarak bulur.",
                isbn: "978-0553213690",
                pageCount: 160,
                publishedDate: nil,
                publisher: "Vintage",
                categories: ["Klasik", "Kurgu"],
                language: "tr",
                userProgress: ReadingProgress(
                    currentPage: 160,
                    totalPages: 160,
                    startedAt: Date().addingTimeInterval(-90*24*60*60), // 90 days ago
                    lastReadAt: Date().addingTimeInterval(-60*24*60*60), // 60 days ago
                    completedAt: Date().addingTimeInterval(-60*24*60*60), // 60 days ago
                    readingStatus: .completed,
                    minutesRead: 420
                ),
                rating: 4.0,
                notes: [],
                isSharedWithPartner: false,
                addedToLibraryAt: Date().addingTimeInterval(-100*24*60*60)
            ),
            Book(
                id: UUID().uuidString,
                title: "Suç ve Ceza",
                authors: ["Fyodor Dostoyevski"],
                coverImageUrl: nil,
                description: "Raskolnikov'un işlediği cinayet sonrası yaşadığı vicdani sorgulamaları anlatır.",
                isbn: "978-0143058142",
                pageCount: 671,
                publishedDate: nil,
                publisher: "Penguin Classics",
                categories: ["Klasik", "Psikolojik"],
                language: "tr",
                userProgress: ReadingProgress(
                    currentPage: 0,
                    totalPages: 671,
                    startedAt: nil,
                    lastReadAt: nil,
                    completedAt: nil,
                    readingStatus: .notStarted,
                    minutesRead: 0
                ),
                rating: nil,
                notes: [],
                isSharedWithPartner: false,
                addedToLibraryAt: Date().addingTimeInterval(-10*24*60*60)
            ),
            Book(
                id: UUID().uuidString,
                title: "Simyacı",
                authors: ["Paulo Coelho"],
                coverImageUrl: nil,
                description: "Santiago'nun kişisel efsanesini keşfetmek için çıktığı yolculuğu anlatır.",
                isbn: "978-0062315007",
                pageCount: 184,
                publishedDate: nil,
                publisher: "HarperOne",
                categories: ["Felsefe", "Roman"],
                language: "tr",
                userProgress: ReadingProgress(
                    currentPage: 100,
                    totalPages: 184,
                    startedAt: Date().addingTimeInterval(-20*24*60*60), // 20 days ago
                    lastReadAt: Date().addingTimeInterval(-1*24*60*60), // yesterday
                    completedAt: nil,
                    readingStatus: .inProgress,
                    minutesRead: 210
                ),
                rating: 4.5,
                notes: [],
                isSharedWithPartner: true,
                addedToLibraryAt: Date().addingTimeInterval(-25*24*60*60)
            )
        ]
        
        self.books = sampleBooks
        self.userLibrary = sampleBooks
        self.updateBookCollections()
    }
} 