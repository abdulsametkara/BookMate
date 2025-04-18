import Foundation

enum ReadingStatus: String, Codable {
    case notStarted = "NOT_STARTED"
    case inProgress = "IN_PROGRESS"
    case finished = "FINISHED"
    
    var displayName: String {
        switch self {
        case .notStarted:
            return "Okumaya Başlanmadı"
        case .inProgress:
            return "Okunuyor"
        case .finished:
            return "Okundu"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .notStarted:
            return "book.closed"
        case .inProgress:
            return "book"
        case .finished:
            return "book.fill"
        }
    }
}

struct ImageLinks: Codable, Equatable {
    let small: String?
    let thumbnail: String?
    let medium: String?
    let large: String?
}

struct Book: Identifiable, Codable, Equatable {
    var id: UUID
    let isbn: String?
    let title: String
    let authors: [String]
    let description: String?
    let pageCount: Int?
    let categories: [String]?
    let imageLinks: ImageLinks?
    let publishedDate: String?
    let publisher: String?
    let language: String?
    
    // Kullanıcı tarafından değiştirilebilen özellikler
    var readingStatus: ReadingStatus = .notStarted
    var readingProgressPercentage: Double = 0
    var userNotes: String?
    
    // Fiyat bilgileri
    var price: Double?
    var currency: String?
    
    // Takip özellikleri
    var startedReading: Date?
    var finishedReading: Date?
    var currentPage: Int?
    var lastReadAt: Date?
    var dateAdded: Date? = Date()
    
    // Hesaplanmış özellikler
    var authorsText: String {
        authors.joined(separator: ", ")
    }
    
    var thumbnailURL: URL? {
        if let urlString = imageLinks?.thumbnail {
            // Google Books API bazen http:// döndürüyor, https:// ile değiştir
            let secureUrlString = urlString.replacingOccurrences(of: "http://", with: "https://")
            return URL(string: secureUrlString)
        }
        return nil
    }
    
    // Eşitlik kontrolü
    static func == (lhs: Book, rhs: Book) -> Bool {
        lhs.id == rhs.id
    }
    
    // Örnek kitaplar
    static var samples: [Book] = [
        Book(
            id: UUID(),
            isbn: "9780060935467",
            title: "To Kill a Mockingbird",
            authors: ["Harper Lee"],
            description: "A classic of modern American literature.",
            pageCount: 336,
            categories: ["Fiction", "Classics"],
            imageLinks: ImageLinks(small: nil, thumbnail: "https://books.google.com/books/content?id=PGR2AwAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api", medium: nil, large: nil),
            publishedDate: "1960-07-11",
            publisher: "Harper Perennial",
            language: "en",
            readingStatus: .inProgress,
            readingProgressPercentage: 45,
            userNotes: "Loving this classic so far!",
            price: 12.99,
            currency: "USD",
            startedReading: Date().addingTimeInterval(-7*24*60*60), // bir hafta önce
            finishedReading: nil,
            currentPage: 150,
            lastReadAt: Date().addingTimeInterval(-24*60*60) // dün
        ),
        Book(
            id: UUID(),
            isbn: "9780743273565",
            title: "The Great Gatsby",
            authors: ["F. Scott Fitzgerald"],
            description: "The Great Gatsby is a 1925 novel by American writer F. Scott Fitzgerald.",
            pageCount: 180,
            categories: ["Fiction", "Classics"],
            imageLinks: ImageLinks(small: nil, thumbnail: "https://books.google.com/books/content?id=iXn5U2IzVH0C&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api", medium: nil, large: nil),
            publishedDate: "1925-04-10",
            publisher: "Scribner",
            language: "en",
            readingStatus: .notStarted,
            readingProgressPercentage: 0,
            userNotes: nil,
            price: 9.99,
            currency: "USD"
        ),
        Book(
            id: UUID(),
            isbn: "9780450040184",
            title: "The Shining",
            authors: ["Stephen King"],
            description: "The Shining is a horror novel by American author Stephen King.",
            pageCount: 447,
            categories: ["Fiction", "Horror"],
            imageLinks: ImageLinks(small: nil, thumbnail: "https://books.google.com/books/content?id=1vy0mQEACAAJ&printsec=frontcover&img=1&zoom=1&source=gbs_api", medium: nil, large: nil),
            publishedDate: "1977-01-28",
            publisher: "Doubleday",
            language: "en",
            readingStatus: .finished,
            readingProgressPercentage: 100,
            userNotes: "One of King's best works!",
            price: 14.99,
            currency: "USD",
            startedReading: Date().addingTimeInterval(-30*24*60*60), // bir ay önce
            finishedReading: Date().addingTimeInterval(-15*24*60*60), // iki hafta önce
            currentPage: 447,
            lastReadAt: Date().addingTimeInterval(-15*24*60*60) // iki hafta önce
        )
    ]
}

// JSON veri işleme yardımcıları
extension Book {
    struct GoogleBooksResponse: Decodable {
        let items: [VolumeInfo]
        
        struct VolumeInfo: Decodable {
            let volumeInfo: BookInfo
            
            struct BookInfo: Decodable {
                let title: String
                let authors: [String]?
                let description: String?
                let pageCount: Int?
                let categories: [String]?
                let imageLinks: ImageLinks?
                let publishedDate: String?
                let publisher: String?
                let language: String?
                let industryIdentifiers: [IndustryIdentifier]?
                
                struct IndustryIdentifier: Decodable {
                    let type: String
                    let identifier: String
                }
            }
        }
    }
    
    // Google Books API'den kitap verilerini Book nesnesine dönüştürür
    static func fromGoogleBooksAPI(_ item: GoogleBooksResponse.VolumeInfo) -> Book {
        let bookInfo = item.volumeInfo
        
        // ISBN'i bulmaya çalış
        let isbn = bookInfo.industryIdentifiers?.first(where: { 
            $0.type == "ISBN_13" || $0.type == "ISBN_10" 
        })?.identifier
        
        return Book(
            id: UUID(),
            isbn: isbn,
            title: bookInfo.title,
            authors: bookInfo.authors ?? ["Yazar Belirtilmemiş"],
            description: bookInfo.description,
            pageCount: bookInfo.pageCount,
            categories: bookInfo.categories,
            imageLinks: bookInfo.imageLinks,
            publishedDate: bookInfo.publishedDate,
            publisher: bookInfo.publisher,
            language: bookInfo.language,
            readingStatus: .notStarted,
            readingProgressPercentage: 0,
            userNotes: nil,
            price: nil,
            currency: nil,
            startedReading: nil,
            finishedReading: nil,
            currentPage: nil,
            lastReadAt: nil
        )
    }
}

// API'den dönen kitap verisi için DTO (Data Transfer Object)
struct GoogleBookResponse: Codable {
    let items: [GoogleBookItem]?
    let totalItems: Int
}

struct GoogleBookItem: Codable {
    let id: String
    let volumeInfo: VolumeInfo
}

struct VolumeInfo: Codable {
    let title: String
    let authors: [String]?
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let industryIdentifiers: [IndustryIdentifier]?
    let pageCount: Int?
    let categories: [String]?
    let imageLinks: GoogleImageLinks?
    let language: String?
}

struct IndustryIdentifier: Codable {
    let type: String
    let identifier: String
}

struct GoogleImageLinks: Codable {
    let smallThumbnail: String?
    let thumbnail: String?
    
    // ImageLinks'e dönüştürme
    func toImageLinks() -> ImageLinks {
        return ImageLinks(
            small: smallThumbnail,
            thumbnail: thumbnail,
            medium: nil,
            large: nil
        )
    }
}

extension GoogleBookItem {
    func toBook() -> Book {
        let isbn = volumeInfo.industryIdentifiers?.first(where: { $0.type == "ISBN_13" })?.identifier
            ?? volumeInfo.industryIdentifiers?.first(where: { $0.type == "ISBN_10" })?.identifier
        
        return Book(
            id: UUID(),
            isbn: isbn,
            title: volumeInfo.title,
            authors: volumeInfo.authors ?? ["Bilinmeyen Yazar"],
            description: volumeInfo.description,
            pageCount: volumeInfo.pageCount,
            categories: volumeInfo.categories,
            imageLinks: volumeInfo.imageLinks?.toImageLinks(),
            publishedDate: volumeInfo.publishedDate,
            publisher: volumeInfo.publisher,
            language: volumeInfo.language,
            readingStatus: .notStarted,
            readingProgressPercentage: 0,
            userNotes: nil,
            price: nil,
            currency: nil,
            startedReading: nil,
            finishedReading: nil,
            currentPage: nil,
            lastReadAt: nil
        )
    }
} 