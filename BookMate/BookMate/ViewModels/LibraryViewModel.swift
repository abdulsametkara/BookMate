import Foundation
import Combine

class LibraryViewModel: ObservableObject {
    // Published properties for the view to observe
    @Published var userBooks: [LibraryBook] = []
    @Published var partnerSharedBooks: [LibraryBook] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var searchResults: [LibraryBook] = []
    @Published var searchQuery: String = ""
    @Published var selectedFilter: BookFilter = .all
    @Published var selectedSortOption: SortOption = .addedDate
    
    // Türkçe versiyon için basitleştirilmiş erişim için
    @Published var books: [LibraryBook] = []
    
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
    
    init(bookService: BookServiceProtocol = DummyBookService()) {
        self.bookService = bookService
        
        // Demo verisiyle başlat
        loadDemoBooks()
        
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
    
    // Demo verisi yükleme
    private func loadDemoBooks() {
        let demoBooks = [
            LibraryBook(id: "1", title: "1984", author: "George Orwell", coverImageURL: nil, progress: 0.7),
            LibraryBook(id: "2", title: "Hayvan Çiftliği", author: "George Orwell", coverImageURL: nil, progress: 1.0),
            LibraryBook(id: "3", title: "Suç ve Ceza", author: "Fyodor Dostoyevski", coverImageURL: nil, progress: 0.3),
            LibraryBook(id: "4", title: "Dönüşüm", author: "Franz Kafka", coverImageURL: nil, progress: 0.0),
            LibraryBook(id: "5", title: "Sefiller", author: "Victor Hugo", coverImageURL: nil, progress: 0.25)
        ]
        
        self.userBooks = demoBooks
        self.books = demoBooks  // Basitleştirilmiş erişim için
        self.applyFiltersAndSort()
    }
    
    // MARK: - Public Methods
    
    func loadLibrary() {
        isLoading = true
        errorMessage = nil
        
        // Gerçek implementasyonda burada API çağrıları yapılacak
        // Şimdilik demo verisi kullanıyoruz
        isLoading = false
    }
    
    func refreshLibrary() {
        loadLibrary()
    }
    
    func addBookToLibrary(book: LibraryBook) {
        isLoading = true
        
        // Demo: sadece listeye ekle
        userBooks.append(book)
        books.append(book)
        applyFiltersAndSort()
        
        isLoading = false
    }
    
    func removeBookFromLibrary(bookId: String) {
        isLoading = true
        
        // Demo: ID'ye göre kitabı kaldır
        userBooks.removeAll(where: { $0.id == bookId })
        books.removeAll(where: { $0.id == bookId })
        applyFiltersAndSort()
        
        isLoading = false
    }
    
    func updateReadingProgress(bookId: String, progress: Double) {
        isLoading = true
        
        // Demo: kitap ilerlemesini güncelle
        if let index = userBooks.firstIndex(where: { $0.id == bookId }) {
            userBooks[index].progress = progress
        }
        
        if let index = books.firstIndex(where: { $0.id == bookId }) {
            books[index].progress = progress
        }
        
        applyFiltersAndSort()
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func searchBooks(query: String) {
        // Demo: basit bir yerel arama
        let lowercaseQuery = query.lowercased()
        searchResults = userBooks.filter {
            $0.title.lowercased().contains(lowercaseQuery) ||
            $0.author.lowercased().contains(lowercaseQuery)
        }
    }
    
    private func applyFiltersAndSort() {
        var filteredBooks = userBooks
        
        // Apply filters
        switch selectedFilter {
        case .all:
            filteredBooks = userBooks
        case .reading:
            filteredBooks = userBooks.filter { $0.progress > 0 && $0.progress < 1.0 }
        case .completed:
            filteredBooks = userBooks.filter { $0.progress >= 1.0 }
        case .notStarted:
            filteredBooks = userBooks.filter { $0.progress == 0 }
        case .shared:
            filteredBooks = userBooks // Demo: şimdilik paylaşım özelliği yok
        }
        
        // Apply sorting
        switch selectedSortOption {
        case .addedDate:
            // Demo: şimdilik sıralama yok, varsayılan sırayı koru
            break
        case .readDate:
            break
        case .title:
            filteredBooks.sort { $0.title < $1.title }
        case .author:
            filteredBooks.sort { $0.author < $1.author }
        case .progress:
            filteredBooks.sort { $0.progress > $1.progress }
        }
        
        userBooks = filteredBooks
    }
    
    // Get books based on reading status
    func booksInProgress() -> [LibraryBook] {
        return userBooks.filter { $0.progress > 0 && $0.progress < 1.0 }
    }
    
    func booksCompleted() -> [LibraryBook] {
        return userBooks.filter { $0.progress >= 1.0 }
    }
    
    func booksNotStarted() -> [LibraryBook] {
        return userBooks.filter { $0.progress == 0 }
    }
}

// Basit bir dummy servis (gerçek implementasyon için)
class DummyBookService: BookServiceProtocol {
    // BookServiceProtocol metotları burada implement edilecek
}

// Gerekli protokol
protocol BookServiceProtocol {
    // Gerekli metotlar burada tanımlanacak
}

// Basit Book modeli
struct LibraryBook: Identifiable {
    var id: String
    var title: String
    var author: String
    var coverImageURL: String?
    var progress: Double // 0.0 - 1.0 arası
} 