import Foundation
import Combine

class LibraryViewModel: ObservableObject {
    // Published properties for the view to observe
    @Published var userBooks: [Book] = []
    @Published var partnerSharedBooks: [Book] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var searchResults: [Book] = []
    @Published var searchQuery: String = ""
    @Published var selectedFilter: BookFilter = .all
    @Published var selectedSortOption: SortOption = .addedDate
    
    // Dependency injection of book service
    private let bookService: BookServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // Filter options for the library
    enum BookFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case reading = "Reading"
        case completed = "Completed"
        case notStarted = "Not Started"
        case shared = "Shared with Partner"
        
        var id: String { self.rawValue }
    }
    
    // Sort options for the library
    enum SortOption: String, CaseIterable, Identifiable {
        case addedDate = "Recently Added"
        case readDate = "Recently Read"
        case title = "Title"
        case author = "Author"
        case progress = "Reading Progress"
        
        var id: String { self.rawValue }
    }
    
    init(bookService: BookServiceProtocol) {
        self.bookService = bookService
        
        // Setup search debounce
        $searchQuery
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                if !query.isEmpty {
                    self?.searchBooks(query: query)
                } else {
                    self?.searchResults = []
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func loadLibrary() {
        isLoading = true
        errorMessage = nil
        
        // Load user books
        bookService.fetchUserBooks()
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
                self?.isLoading = false
            }, receiveValue: { [weak self] books in
                self?.userBooks = books
                self?.applyFiltersAndSort()
            })
            .store(in: &cancellables)
        
        // Load partner shared books
        bookService.fetchPartnerSharedBooks()
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] books in
                self?.partnerSharedBooks = books
                self?.applyFiltersAndSort()
            })
            .store(in: &cancellables)
    }
    
    func refreshLibrary() {
        loadLibrary()
    }
    
    func addBookToLibrary(book: Book) {
        isLoading = true
        
        bookService.addBookToLibrary(book: book)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
                self?.isLoading = false
            }, receiveValue: { [weak self] success in
                if success {
                    self?.refreshLibrary()
                }
            })
            .store(in: &cancellables)
    }
    
    func removeBookFromLibrary(bookId: String) {
        isLoading = true
        
        bookService.removeBookFromLibrary(bookId: bookId)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
                self?.isLoading = false
            }, receiveValue: { [weak self] success in
                if success {
                    self?.refreshLibrary()
                }
            })
            .store(in: &cancellables)
    }
    
    func updateReadingProgress(bookId: String, progress: ReadingProgress) {
        isLoading = true
        
        bookService.updateReadingProgress(bookId: bookId, progress: progress)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
                self?.isLoading = false
            }, receiveValue: { [weak self] success in
                if success {
                    self?.refreshLibrary()
                }
            })
            .store(in: &cancellables)
    }
    
    func shareBookWithPartner(bookId: String, shared: Bool) {
        isLoading = true
        
        bookService.shareBookWithPartner(bookId: bookId, shared: shared)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
                self?.isLoading = false
            }, receiveValue: { [weak self] success in
                if success {
                    self?.refreshLibrary()
                }
            })
            .store(in: &cancellables)
    }
    
    func addNoteToBook(bookId: String, note: ReadingNote) {
        isLoading = true
        
        bookService.addNoteToBook(bookId: bookId, note: note)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
                self?.isLoading = false
            }, receiveValue: { [weak self] success in
                if success {
                    self?.refreshLibrary()
                }
            })
            .store(in: &cancellables)
    }
    
    func deleteNote(bookId: String, noteId: String) {
        isLoading = true
        
        bookService.deleteNote(bookId: bookId, noteId: noteId)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
                self?.isLoading = false
            }, receiveValue: { [weak self] success in
                if success {
                    self?.refreshLibrary()
                }
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    
    private func searchBooks(query: String) {
        isLoading = true
        
        bookService.searchBooks(query: query)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
                self?.isLoading = false
            }, receiveValue: { [weak self] books in
                self?.searchResults = books
            })
            .store(in: &cancellables)
    }
    
    private func applyFiltersAndSort() {
        var filteredBooks = userBooks
        
        // Apply filters
        switch selectedFilter {
        case .all:
            filteredBooks = userBooks
        case .reading:
            filteredBooks = userBooks.filter { $0.userProgress?.readingStatus == .inProgress }
        case .completed:
            filteredBooks = userBooks.filter { $0.userProgress?.readingStatus == .completed }
        case .notStarted:
            filteredBooks = userBooks.filter { $0.userProgress?.readingStatus == .notStarted }
        case .shared:
            filteredBooks = userBooks.filter { $0.isSharedWithPartner }
        }
        
        // Apply sorting
        switch selectedSortOption {
        case .addedDate:
            filteredBooks.sort { ($0.addedToLibraryAt ?? Date.distantPast) > ($1.addedToLibraryAt ?? Date.distantPast) }
        case .readDate:
            filteredBooks.sort { ($0.userProgress?.lastReadAt ?? Date.distantPast) > ($1.userProgress?.lastReadAt ?? Date.distantPast) }
        case .title:
            filteredBooks.sort { $0.title < $1.title }
        case .author:
            filteredBooks.sort { $0.authorDisplay < $1.authorDisplay }
        case .progress:
            filteredBooks.sort { ($0.userProgress?.completionPercentage ?? 0) > ($1.userProgress?.completionPercentage ?? 0) }
        }
        
        userBooks = filteredBooks
    }
    
    // Get books based on reading status
    func booksInProgress() -> [Book] {
        return userBooks.filter { $0.userProgress?.readingStatus == .inProgress }
    }
    
    func booksCompleted() -> [Book] {
        return userBooks.filter { $0.userProgress?.readingStatus == .completed }
    }
    
    func booksNotStarted() -> [Book] {
        return userBooks.filter { $0.userProgress?.readingStatus == .notStarted }
    }
} 