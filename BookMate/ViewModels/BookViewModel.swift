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
        let sampleBook1 = Book(
            id: UUID().uuidString,
            isbn: "9780451524935",
            title: "1984",
            subtitle: "Distopik Roman",
            authors: ["George Orwell"],
            publisher: "Signet Classic",
            publishedDate: nil,
            description: "Öncü distopik bir roman, totaliter bir hükümetin kontrol ettiği bir toplumu anlatır.",
            pageCount: 328,
            categories: ["Kurgu", "Klasikler", "Distopya"],
            imageLinks: BookImageLinks(thumbnail: "https://covers.openlibrary.org/b/id/8231579-M.jpg", large: "https://covers.openlibrary.org/b/id/8231579-L.jpg"),
            language: "tr",
            dateAdded: Date(),
            startedReading: Date().addingTimeInterval(-30*24*60*60),
            finishedReading: nil,
            currentPage: 156,
            readingStatus: .inProgress,
            isFavorite: true,
            userRating: 4.7,
            userNotes: "Bu kitabı eşimle birlikte okuyoruz, harika bir deneyim.",
            highlightedPassages: [],
            bookmarks: [],
            readingTime: 1240*60,
            lastReadingSession: Date().addingTimeInterval(-2*24*60*60),
            readingSessions: [],
            recommendedBy: nil,
            recommendedDate: nil,
            sharedCollectionIds: [],
            partnerNotes: nil
        )
        
        let sampleBook2 = Book(
            id: UUID().uuidString,
            isbn: "9780140283334",
            title: "Suç ve Ceza",
            subtitle: "Psikolojik Roman",
            authors: ["Fyodor Dostoyevski"],
            publisher: "Penguin Classics",
            publishedDate: nil,
            description: "Raskolnikov adlı bir öğrencinin psikolojik ve ahlaki çatışmalarını anlatan klasik bir roman.",
            pageCount: 671,
            categories: ["Klasikler", "Kurgu", "Psikolojik"],
            imageLinks: BookImageLinks(thumbnail: "https://covers.openlibrary.org/b/id/8412383-M.jpg", large: "https://covers.openlibrary.org/b/id/8412383-L.jpg"),
            language: "tr",
            dateAdded: Date().addingTimeInterval(-60*24*60*60),
            startedReading: Date().addingTimeInterval(-50*24*60*60),
            finishedReading: Date().addingTimeInterval(-5*24*60*60),
            currentPage: 671,
            readingStatus: .finished,
            isFavorite: true,
            userRating: 5.0,
            userNotes: "Şimdiye kadar okuduğum en etkileyici kitaplardan biri.",
            highlightedPassages: [],
            bookmarks: [],
            readingTime: 3600*60,
            lastReadingSession: Date().addingTimeInterval(-5*24*60*60),
            readingSessions: [],
            recommendedBy: nil,
            recommendedDate: nil,
            sharedCollectionIds: [],
            partnerNotes: nil
        )
        
        let sampleBook3 = Book(
            id: UUID().uuidString,
            isbn: "9780316219266",
            title: "İkigai: Japonların Uzun ve Mutlu Yaşam Sırrı",
            subtitle: "Kişisel Gelişim",
            authors: ["Hector Garcia", "Francesc Miralles"],
            publisher: "Penguin Life",
            publishedDate: nil,
            description: "Japonların mutlu ve anlamlı bir yaşam sürmek için kullandıkları ikigai kavramını anlatan kitap.",
            pageCount: 208,
            categories: ["Kişisel Gelişim", "Psikoloji", "Felsefe"],
            imageLinks: BookImageLinks(thumbnail: "https://covers.openlibrary.org/b/id/8231579-M.jpg", large: "https://covers.openlibrary.org/b/id/8231579-L.jpg"),
            language: "tr",
            dateAdded: Date().addingTimeInterval(-10*24*60*60),
            startedReading: nil,
            finishedReading: nil,
            currentPage: 0,
            readingStatus: .notStarted,
            isFavorite: false,
            userRating: nil,
            userNotes: nil,
            highlightedPassages: [],
            bookmarks: [],
            readingTime: 0,
            lastReadingSession: nil,
            readingSessions: [],
            recommendedBy: "Eşim",
            recommendedDate: Date().addingTimeInterval(-10*24*60*60),
            sharedCollectionIds: [],
            partnerNotes: "Bu kitabı birlikte okuyabiliriz. İçeriği çok ilgi çekici."
        )
        
        books = [sampleBook1, sampleBook2, sampleBook3]
        userLibrary = books
        currentlyReadingBooks = [sampleBook1]
        recentlyAddedBooks = [sampleBook3, sampleBook1, sampleBook2]
    }
} 