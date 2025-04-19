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
        
        // Allbooks'a tüm örnek kitapları ekleyelim
        print("BookViewModel başlatıldı, kitap sayısı: \(allBooks.count)")
        
        // Arama için ekstra kitaplar ekleyelim
        addSampleBooksForSearch()
    }
    
    private func loadBooks() {
        // Örnek kitaplar
        allBooks = Book.samples
        userLibrary = allBooks
        print("Örnek kitaplar yüklendi: \(allBooks.count) kitap")
    }
    
    // Arama için çeşitli örnek kitaplar ekleyelim
    private func addSampleBooksForSearch() {
        // Popüler kitaplar listesi - arama için daha fazla seçenek
        let extraSampleBooks: [Book] = [
            Book(
                id: UUID(),
                isbn: "9780439023481",
                title: "Açlık Oyunları",
                authors: ["Suzanne Collins"],
                description: "Açlık Oyunları, Suzanne Collins tarafından yazılmış distopik bir macera romanıdır.",
                pageCount: 374,
                categories: ["Genç Yetişkin", "Distopya", "Bilim Kurgu"],
                imageLinks: ImageLinks(small: nil, thumbnail: "https://covers.openlibrary.org/b/id/8231446-M.jpg", medium: nil, large: nil),
                publishedDate: "2008-09-14",
                publisher: "Scholastic",
                language: "tr",
                readingStatus: .notStarted
            ),
            Book(
                id: UUID(),
                isbn: "9789750719387",
                title: "Harry Potter ve Felsefe Taşı",
                authors: ["J.K. Rowling"],
                description: "Harry Potter serisinin ilk kitabı.",
                pageCount: 276,
                categories: ["Fantastik", "Macera"],
                imageLinks: ImageLinks(small: nil, thumbnail: "https://covers.openlibrary.org/b/id/8234463-M.jpg", medium: nil, large: nil),
                publishedDate: "1997-06-26",
                publisher: "Yapı Kredi Yayınları",
                language: "tr",
                readingStatus: .notStarted
            ),
            Book(
                id: UUID(),
                isbn: "9789753424080",
                title: "Yüzüklerin Efendisi: Yüzük Kardeşliği",
                authors: ["J.R.R. Tolkien"],
                description: "Yüzüklerin Efendisi üçlemesinin ilk kitabı.",
                pageCount: 423,
                categories: ["Fantastik", "Macera"],
                imageLinks: ImageLinks(small: nil, thumbnail: "https://covers.openlibrary.org/b/id/8472751-M.jpg", medium: nil, large: nil),
                publishedDate: "1954-07-29",
                publisher: "Metis Yayınları",
                language: "tr",
                readingStatus: .notStarted
            )
        ]
        
        // Kitapları tüm listelere ekle
        allBooks.append(contentsOf: extraSampleBooks)
        print("Arama için ek örnek kitaplar eklendi. Toplam kitap sayısı: \(allBooks.count)")
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
    
    func addBook(_ book: Book) {
        // Kitabın zaten kütüphanede olup olmadığını kontrol et
        if userLibrary.contains(where: { $0.title == book.title && (book.authors.first ?? "") == ($0.authors.first ?? "") }) {
            print("Bu kitap zaten kütüphanenizde var.")
            return
        }
        
        // Kitabı şu anki tarihle birlikte ekle
        var newBook = book
        newBook.dateAdded = Date()
        newBook.lastReadAt = Date()
        
        // Kütüphaneye ekle
        userLibrary.append(newBook)
        
        // Tüm kitaplar listesine de ekle (eğer zaten yoksa)
        if !allBooks.contains(where: { $0.id == book.id }) {
            allBooks.append(newBook)
        }
        
        print("Kitap başarıyla eklendi: \(book.title)")
    }
    
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
    
    // Kitabı "şu an okunuyor" olarak işaretler
    func markAsCurrentlyReading(_ book: Book) {
        // Önce şu an okunan kitabı varsa onun durumunu güncelle
        if let current = currentlyReadingBook, let index = userLibrary.firstIndex(where: { $0.id == current.id }) {
            userLibrary[index].readingStatus = .notStarted
        }
        
        // Yeni kitabı "okunuyor" olarak işaretle
        if let index = userLibrary.firstIndex(where: { $0.id == book.id }) {
            userLibrary[index].readingStatus = .inProgress
            userLibrary[index].startedReading = Date()
            userLibrary[index].lastReadAt = Date()
        }
    }
} 