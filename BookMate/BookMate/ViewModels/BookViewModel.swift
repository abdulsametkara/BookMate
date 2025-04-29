import Foundation
import Combine

class BookViewModel: ObservableObject {
    @Published var allBooks: [GoogleBook] = []
    @Published var userLibrary: [GoogleBook] = []
    @Published var wishlistBooks: [GoogleBook] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // UserViewModel referansı - istatistikleri güncellemek için
    var userViewModel: BookMate.UserViewModel?
    
    // UserDefaults için anahtar sabitleri
    private let userLibraryKey = "userLibrary"
    private let wishlistBooksKey = "wishlistBooks"
    
    init() {
        // Önce kaydedilmiş veriyi yükle
        loadSavedData()
        
        // Eğer kaydedilmiş veri yoksa, örnek kitapları yükle
        if userLibrary.isEmpty {
            loadBooks()
            
            // Allbooks'a tüm örnek kitapları ekleyelim
            print("BookViewModel başlatıldı, kitap sayısı: \(allBooks.count)")
            
            // Arama için ekstra kitaplar ekleyelim
            addSampleBooksForSearch()
        }
    }
    
    // MARK: - Data Persistence Methods
    
    // Verileri yükle
    private func loadSavedData() {
        // Kütüphane kitaplarını yükle
        if let savedLibraryData = UserDefaults.standard.data(forKey: userLibraryKey) {
            do {
                let decoder = JSONDecoder()
                userLibrary = try decoder.decode([GoogleBook].self, from: savedLibraryData)
                print("Kaydedilmiş kütüphane yüklendi: \(userLibrary.count) kitap")
                
                // allBooks'a kütüphane kitaplarını ekle
                allBooks = userLibrary
            } catch {
                print("Kütüphane verisi yüklenirken hata: \(error.localizedDescription)")
                userLibrary = []
            }
        }
        
        // İstek listesi kitaplarını yükle
        if let savedWishlistData = UserDefaults.standard.data(forKey: wishlistBooksKey) {
            do {
                let decoder = JSONDecoder()
                wishlistBooks = try decoder.decode([GoogleBook].self, from: savedWishlistData)
                print("Kaydedilmiş istek listesi yüklendi: \(wishlistBooks.count) kitap")
                
                // İstek listesindeki kitapları da allBooks'a ekle (eğer zaten yoksa)
                for book in wishlistBooks {
                    if !allBooks.contains(where: { $0.id == book.id }) {
                        allBooks.append(book)
                    }
                }
            } catch {
                print("İstek listesi verisi yüklenirken hata: \(error.localizedDescription)")
                wishlistBooks = []
            }
        }
    }
    
    // Verileri kaydet - artık public olarak kullanılabilir
    func saveData() {
        // Kütüphane kitaplarını kaydet
        do {
            let encoder = JSONEncoder()
            let encodedLibrary = try encoder.encode(userLibrary)
            UserDefaults.standard.set(encodedLibrary, forKey: userLibraryKey)
            print("Kütüphane kaydedildi: \(userLibrary.count) kitap")
        } catch {
            print("Kütüphane verisi kaydedilirken hata: \(error.localizedDescription)")
        }
        
        // İstek listesi kitaplarını kaydet
        do {
            let encoder = JSONEncoder()
            let encodedWishlist = try encoder.encode(wishlistBooks)
            UserDefaults.standard.set(encodedWishlist, forKey: wishlistBooksKey)
            print("İstek listesi kaydedildi: \(wishlistBooks.count) kitap")
        } catch {
            print("İstek listesi verisi kaydedilirken hata: \(error.localizedDescription)")
        }
    }
    
    private func loadBooks() {
        // Örnek kitaplar
        allBooks = GoogleBook.samples
        userLibrary = allBooks
        print("Örnek kitaplar yüklendi: \(allBooks.count) kitap")
    }
    
    // Arama için çeşitli örnek kitaplar ekleyelim
    private func addSampleBooksForSearch() {
        // Popüler kitaplar listesi - arama için daha fazla seçenek
        let extraSampleBooks: [GoogleBook] = [
            GoogleBook(
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
            GoogleBook(
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
            GoogleBook(
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
        userLibrary.append(contentsOf: extraSampleBooks) // Kütüphaneye de ekleyelim
        print("Arama için ek örnek kitaplar eklendi. Toplam kitap sayısı: \(allBooks.count)")
    }
    
    // MARK: - Computed Properties
    
    var currentlyReadingBook: GoogleBook? {
        userLibrary.first { $0.readingStatus == .inProgress }
    }
    
    var currentlyReadingBooks: [GoogleBook] {
        userLibrary.filter { $0.readingStatus == .inProgress }
    }
    
    var recentlyAddedBooks: [GoogleBook] {
        allBooks.sorted { (book1: GoogleBook, book2: GoogleBook) -> Bool in
            return (book1.dateAdded ?? Date()) > (book2.dateAdded ?? Date())
        }.prefix(5).map { $0 }
    }
    
    var completedBooks: [GoogleBook] {
        userLibrary.filter { $0.readingStatus == .finished }
    }
    
    // MARK: - Wishlist Functions
    
    func addToWishlist(_ book: GoogleBook) {
        guard !isInWishlist(book) else { return }
        
        // Kitabı istek listesine ekle
        wishlistBooks.append(book)
        
        // Tüm kitaplar listesine de ekle (eğer zaten yoksa)
        if !allBooks.contains(where: { $0.id == book.id }) {
            allBooks.append(book)
        }
        
        saveData() // Veriyi kaydet
        objectWillChange.send() // UI güncellemesi için
    }
    
    func removeFromWishlist(_ book: GoogleBook) {
        wishlistBooks.removeAll { $0.id == book.id }
        saveData() // Veriyi kaydet
        objectWillChange.send() // UI güncellemesi için
    }
    
    func isInWishlist(_ book: GoogleBook) -> Bool {
        wishlistBooks.contains { $0.id == book.id }
    }
    
    func addToLibrary(_ book: GoogleBook) {
        // Eğer kitap zaten kütüphanede varsa, işlem yapma
        guard !userLibrary.contains(where: { $0.id == book.id }) else { return }
        
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
        
        saveData() // Veriyi kaydet
        objectWillChange.send() // UI güncellemesi için
        print("Kitap başarıyla kütüphaneye eklendi: \(book.title)")
    }
    
    // İstek listesinden kütüphaneye ekle
    func moveFromWishlistToLibrary(_ book: GoogleBook) {
        // Kitabı kütüphaneye ekle
        if !userLibrary.contains(where: { $0.id == book.id }) {
            var libraryBook = book
            libraryBook.dateAdded = Date()
            userLibrary.append(libraryBook)
            
            // İstek listesinden kaldır (opsiyonel)
            wishlistBooks.removeAll { $0.id == book.id }
            
            saveData()
            objectWillChange.send()
            print("Kitap istek listesinden kütüphaneye taşındı: \(book.title)")
        }
    }
    
    // MARK: - Book Management Functions
    
    func updateProgress(for book: GoogleBook, newPage: Int, completed: Bool) {
        if let index = userLibrary.firstIndex(where: { $0.id == book.id }) {
            // Update page
            userLibrary[index].currentPage = newPage
            userLibrary[index].lastReadAt = Date()
            
            // Update reading progress percentage
            if let pageCount = userLibrary[index].pageCount, pageCount > 0 {
                let progressPercentage = min(Double(newPage) / Double(pageCount) * 100.0, 100.0)
                userLibrary[index].readingProgressPercentage = progressPercentage
            }
            
            // Update status based on completed flag
            if completed {
                userLibrary[index].readingStatus = .finished
                userLibrary[index].finishedReading = Date()
                userLibrary[index].readingProgressPercentage = 100.0
            } else {
                userLibrary[index].readingStatus = .inProgress
                if userLibrary[index].startedReading == nil {
                    userLibrary[index].startedReading = Date()
                }
            }
            
            saveData()
            
            // Kullanıcı istatistiklerini güncelle
            if let userViewModel = self.userViewModel {
                userViewModel.updateUserStatistics(with: self)
            }
        }
    }
    
    func addBook(_ book: GoogleBook) {
        // Kitabın zaten kütüphanede olup olmadığını kontrol et
        if userLibrary.contains(where: { $0.id == book.id }) {
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
        
        saveData() // Veriyi kaydet
        objectWillChange.send() // UI güncellemesi için
        print("Kitap başarıyla eklendi: \(book.title)")
    }
    
    func updateBookStatus(_ book: GoogleBook, status: ReadingStatus) {
        if let index = userLibrary.firstIndex(where: { $0.id == book.id }) {
            userLibrary[index].readingStatus = status
            
            // Update startedReading or finishedReading dates based on status
            if status == .inProgress && userLibrary[index].startedReading == nil {
                userLibrary[index].startedReading = Date()
            } else if status == .finished && userLibrary[index].finishedReading == nil {
                userLibrary[index].finishedReading = Date()
            }
            
            saveData() // Veriyi kaydet
        }
    }
    
    func updateCurrentPage(_ book: GoogleBook, page: Int) {
        if let index = userLibrary.firstIndex(where: { $0.id == book.id }) {
            userLibrary[index].currentPage = page
            userLibrary[index].lastReadAt = Date()
            
            // Update reading progress percentage
            if let pageCount = userLibrary[index].pageCount, pageCount > 0 {
                let progressPercentage = min(Double(page) / Double(pageCount) * 100.0, 100.0)
                userLibrary[index].readingProgressPercentage = progressPercentage
            }
            
            // If book wasn't in progress, update status
            if userLibrary[index].readingStatus != .inProgress {
                userLibrary[index].readingStatus = .inProgress
                
                // Set startedReading if not already set
                if userLibrary[index].startedReading == nil {
                    userLibrary[index].startedReading = Date()
                }
            }
            
            // If current page equals or exceeds page count, mark as finished
            if let pageCount = book.pageCount, page >= pageCount {
                userLibrary[index].readingStatus = .finished
                userLibrary[index].finishedReading = Date()
                userLibrary[index].readingProgressPercentage = 100.0
            }
            
            saveData() // Veriyi kaydet
            
            // Kullanıcı istatistiklerini güncelle
            if let userViewModel = self.userViewModel {
                userViewModel.updateUserStatistics(with: self)
            }
        }
    }
    
    // Kitabı "şu an okunuyor" olarak işaretler
    func markAsCurrentlyReading(_ book: GoogleBook) {
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
        
        saveData() // Veriyi kaydet
    }
    
    // Kütüphaneden kitap silme işlemi
    func removeFromLibrary(_ book: GoogleBook) {
        print("Kütüphaneden kitap kaldırılıyor: \(book.title)")
        
        // Silme işleminden önce kitabı al
        _ = userLibrary.first(where: { $0.id == book.id })
        
        // Kütüphaneden kitabı sil
        let initialCount = userLibrary.count
        userLibrary.removeAll { $0.id == book.id }
        let finalCount = userLibrary.count
        
        // Silme işleminin sonucunu kontrol et
        if initialCount != finalCount {
            print("Kitap başarıyla kaldırıldı: \(book.title)")
            
            // Değişikliği hemen yayınla
            objectWillChange.send()
            
            // Değişiklikleri kaydedelim
            saveData()
            
            // Son durumu konsola yazdır
            print("Kütüphane güncel kitap sayısı: \(userLibrary.count)")
        } else {
            print("Kitap kaldırılamadı! ID: \(book.id), Title: \(book.title)")
            
            // Alternatif silme yöntemi dene
            if let index = userLibrary.firstIndex(where: { $0.id == book.id }) {
                userLibrary.remove(at: index)
                print("Alternatif yöntemle kitap kaldırıldı: \(book.title)")
                
                // Değişikliği hemen yayınla
                objectWillChange.send()
                
                // Değişiklikleri kaydedelim
                saveData()
            }
        }
        
        // allBooks listesindeki ilgili kitabın durumunu notStarted olarak işaretle
        // böylece yeniden eklendiğinde başlangıç durumunda olur
        if let index = allBooks.firstIndex(where: { $0.id == book.id }) {
            allBooks[index].readingStatus = .notStarted
            allBooks[index].readingProgressPercentage = 0
            allBooks[index].currentPage = 0
            allBooks[index].startedReading = nil
            allBooks[index].finishedReading = nil
        }
    }
    
    // Yeni eklenen kitapları da kütüphaneye otomatik ekle
    func synchronizeBooks() {
        var didUpdate = false
        
        // Tüm kitaplar ile kütüphane kitaplarını senkronize et
        for book in allBooks {
            if !userLibrary.contains(where: { $0.id == book.id }) {
                var updatedBook = book
                updatedBook.dateAdded = updatedBook.dateAdded ?? Date()
                userLibrary.append(updatedBook)
                didUpdate = true
            }
        }
        
        // Değişiklik olduysa kaydet ve UI'ı güncelle
        if didUpdate {
            saveData()
            objectWillChange.send()
            print("Kütüphane kitapları senkronize edildi. Güncel kitap sayısı: \(userLibrary.count)")
        }
    }
} 