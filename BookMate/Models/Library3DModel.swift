import Foundation
import SceneKit

struct BookshelfLevel {
    var id: String
    var capacity: Int
    var books: [Book]
    var position: SCNVector3
    
    init(id: String = UUID().uuidString, 
         capacity: Int = 10, 
         books: [Book] = [], 
         position: SCNVector3 = SCNVector3Zero) {
        self.id = id
        self.capacity = capacity
        self.books = books
        self.position = position
    }
    
    var isFull: Bool {
        return books.count >= capacity
    }
    
    var isEmpty: Bool {
        return books.isEmpty
    }
    
    var availableSpace: Int {
        return capacity - books.count
    }
}

struct Bookshelf {
    var id: String
    var name: String
    var levels: [BookshelfLevel]
    var position: SCNVector3
    var rotation: SCNVector4
    
    init(id: String = UUID().uuidString,
         name: String = "Kütüphane",
         levels: [BookshelfLevel] = [],
         position: SCNVector3 = SCNVector3Zero,
         rotation: SCNVector4 = SCNVector4Zero) {
        self.id = id
        self.name = name
        self.levels = levels
        self.position = position
        self.rotation = rotation
    }
    
    var totalCapacity: Int {
        return levels.reduce(0) { $0 + $1.capacity }
    }
    
    var totalBooks: Int {
        return levels.reduce(0) { $0 + $1.books.count }
    }
    
    var isFull: Bool {
        return totalBooks >= totalCapacity
    }
    
    // Kitaplık genişleme mekanizması için tüm boşluklar
    var availableSpace: Int {
        return totalCapacity - totalBooks
    }
    
    // Kitabı ekleyebileceğimiz ilk boş yeri bulur
    func findFirstAvailableLevel() -> Int? {
        return levels.firstIndex { !$0.isFull }
    }
    
    // Belirli bir kapasiteye ulaşınca yeni kitaplık raf seviyesi eklenir
    mutating func expandIfNeeded() {
        if availableSpace < 5 {
            let newLevelPosition = SCNVector3(0, Float(levels.count) * 0.3, 0)
            let newLevel = BookshelfLevel(capacity: 10, position: newLevelPosition)
            levels.append(newLevel)
        }
    }
}

struct Library3D {
    var id: String
    var bookshelves: [Bookshelf]
    var displayMode: DisplayMode
    var viewRotation: SCNVector4
    
    enum DisplayMode: String, CaseIterable, Identifiable {
        case chronological = "Kronolojik"
        case category = "Kategori"
        case author = "Yazar"
        case color = "Renk"
        
        var id: String { self.rawValue }
    }
    
    init(id: String = UUID().uuidString,
         bookshelves: [Bookshelf] = [],
         displayMode: DisplayMode = .chronological,
         viewRotation: SCNVector4 = SCNVector4(0, 1, 0, 0)) {
        self.id = id
        self.bookshelves = bookshelves
        self.displayMode = displayMode
        self.viewRotation = viewRotation
    }
    
    // Toplam kitap kapasitesi
    var totalCapacity: Int {
        return bookshelves.reduce(0) { $0 + $1.totalCapacity }
    }
    
    // Toplam kitap sayısı
    var totalBooks: Int {
        return bookshelves.reduce(0) { $0 + $1.totalBooks }
    }
    
    // Kitaplığa kitap ekleme
    mutating func addBook(_ book: Book) {
        // Kitap tamamlandıysa ekleyebiliriz
        guard book.progress >= 1.0 else { return }
        
        // Kitaplık boşsa ilk kitaplığı oluştur
        if bookshelves.isEmpty {
            let firstLevel = BookshelfLevel(capacity: 10)
            let firstBookshelf = Bookshelf(name: "Ana Kütüphane", levels: [firstLevel])
            bookshelves.append(firstBookshelf)
        }
        
        // Kitabı ekleyebileceğimiz ilk kitaplık ve rafı bul
        for (bookshelfIndex, var bookshelf) in bookshelves.enumerated() {
            if let levelIndex = bookshelf.findFirstAvailableLevel() {
                var level = bookshelf.levels[levelIndex]
                level.books.append(book)
                bookshelf.levels[levelIndex] = level
                bookshelves[bookshelfIndex] = bookshelf
                
                // Gerekirse kitaplık raflığını genişlet
                bookshelf.expandIfNeeded()
                bookshelves[bookshelfIndex] = bookshelf
                return
            }
        }
        
        // Tüm kitaplıklar doluysa yeni bir kitaplık oluştur
        let newLevelPosition = SCNVector3(0, 0, 0)
        let newLevel = BookshelfLevel(capacity: 10, position: newLevelPosition)
        var newBookshelf = Bookshelf(
            name: "Kitaplık \(bookshelves.count + 1)", 
            levels: [newLevel],
            position: SCNVector3(Float(bookshelves.count) * 1.5, 0, 0)
        )
        
        // Yeni kitaplığa kitabı ekle
        var level = newBookshelf.levels[0]
        level.books.append(book)
        newBookshelf.levels[0] = level
        
        bookshelves.append(newBookshelf)
    }
    
    // Kitapları gösterme moduna göre düzenle
    mutating func organizeByDisplayMode() {
        var allBooks: [Book] = []
        
        // Önce tüm kitapları topla
        for bookshelf in bookshelves {
            for level in bookshelf.levels {
                allBooks.append(contentsOf: level.books)
            }
        }
        
        // Kitapları gösterme moduna göre sırala
        switch displayMode {
        case .chronological:
            allBooks.sort { 
                ($0.finishDate ?? Date.distantPast) > ($1.finishDate ?? Date.distantPast) 
            }
        case .category:
            allBooks.sort { $0.genre < $1.genre }
        case .author:
            allBooks.sort { $0.author < $1.author }
        case .color:
            // Renk sıralaması gerçek uygulamada kitap kapak rengine göre yapılabilir
            // Bu örnekte basit olması için alfabetik sıralıyoruz
            allBooks.sort { $0.title < $1.title }
        }
        
        // Kitaplıkları temizle
        for i in 0..<bookshelves.count {
            for j in 0..<bookshelves[i].levels.count {
                bookshelves[i].levels[j].books.removeAll()
            }
        }
        
        // Sıralanmış kitapları tekrar kitaplıklara ekle
        for book in allBooks {
            addBook(book)
        }
    }
    
    // Örnek kütüphane oluşturucu
    static func createSampleLibrary(with books: [Book]) -> Library3D {
        var library = Library3D()
        
        // Sadece tamamlanmış kitapları ekle
        for book in books.filter({ $0.progress >= 1.0 }) {
            library.addBook(book)
        }
        
        return library
    }
} 