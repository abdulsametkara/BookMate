import Foundation
import Combine

class GoogleBooksService {
    static let shared = GoogleBooksService()
    
    private let baseURL = "https://www.googleapis.com/books/v1/volumes"
    private let apiKey: String
    private let session: URLSession
    
    // Önbellek yapısı
    private var cache: [String: (data: Any, timestamp: Date)] = [:]
    private let cacheDuration: TimeInterval = 7 * 24 * 60 * 60 // 7 gün
    
    private init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
        
        print("Google Books API servisi başlatıldı.")
    }
    
    // MARK: - Public Methods
    
    /// ISBN ile kitap arama
    func searchByISBN(_ isbn: String) -> AnyPublisher<Book?, Error> {
        let query = "isbn:\(isbn)"
        return search(query: query)
            .map { response -> Book? in
                guard let item = response.items?.first else { return nil }
                return self.convertToBook(item)
            }
            .eraseToAnyPublisher()
    }
    
    /// Başlık veya yazar ile kitap arama
    func searchBooks(title: String? = nil, author: String? = nil, limit: Int = 10) -> AnyPublisher<[Book], Error> {
        var queryItems = [String]()
        
        if let title = title, !title.isEmpty {
            queryItems.append("intitle:\(title)")
        }
        
        if let author = author, !author.isEmpty {
            queryItems.append("inauthor:\(author)")
        }
        
        let query = queryItems.joined(separator: "+")
        return search(query: query, maxResults: limit)
            .map { response -> [Book] in
                guard let items = response.items else { return [] }
                return items.compactMap { self.convertToBook($0) }
            }
            .eraseToAnyPublisher()
    }
    
    /// Kitap detaylarını getir
    func getBookDetails(bookId: String) async throws -> Book {
        // Önbellekte varsa ve süresi geçmediyse, önbellekten getir
        if let cachedResult = getCachedResult(for: "book_\(bookId)") as? Book {
            return cachedResult
        }
        
        // URL oluştur
        guard let url = URL(string: "\(baseURL)/\(bookId)?key=\(apiKey)") else {
            throw NSError(domain: "GoogleBooksService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Geçersiz URL"])
        }
        
        // API isteği
        let (data, response) = try await session.data(from: url)
        
        // Yanıt kontrolü
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "GoogleBooksService", code: 2, userInfo: [NSLocalizedDescriptionKey: "API isteği başarısız oldu"])
        }
        
        // Veriyi ayrıştır
        let volumeItem = try JSONDecoder().decode(VolumeItem.self, from: data)
        
        // Kitap modeline dönüştür
        guard let book = convertToBook(volumeInfo: volumeItem.volumeInfo) else {
            throw NSError(domain: "GoogleBooksService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Kitap bilgisi dönüştürülemiyor"])
        }
        
        // Sonucu önbelleğe al
        cacheResult(book, for: "book_\(bookId)")
        
        return book
    }
    
    // MARK: - Private Helper Methods
    
    /// GoogleBooks API yanıtını Book modeline dönüştür
    private func convertToBook(_ item: VolumeItem) -> Book? {
        let volumeInfo = item.volumeInfo
        
        // ISBN değerini bulma
        let isbn = volumeInfo.industryIdentifiers?.first(where: { $0.type == ISBNType.isbn13.rawValue })?.identifier
            ?? volumeInfo.industryIdentifiers?.first(where: { $0.type == ISBNType.isbn10.rawValue })?.identifier
            ?? ""
        
        // Yazarları birleştirme
        let authors = volumeInfo.authors?.joined(separator: ", ") ?? "Bilinmeyen Yazar"
        
        // Kapak resmini alma
        let coverURL = volumeInfo.imageLinks?.thumbnail?.absoluteString ?? ""
        
        return Book(
            id: item.id,
            title: volumeInfo.title,
            author: authors,
            coverURL: coverURL,
            isbn: isbn,
            pageCount: volumeInfo.pageCount ?? 0,
            currentPage: 0,
            dateAdded: Date(),
            dateUpdated: Date(),
            genre: volumeInfo.categories?.first ?? "",
            notes: "",
            rating: 0,
            completionDate: nil,
            isSharedWithPartner: false,
            userId: "",
            partnerUserId: nil
        )
    }
    
    // MARK: - Cache Methods
    
    /// Sonucu önbelleğe al
    private func cacheResult(_ result: Any, for key: String) {
        cache[key] = (data: result, timestamp: Date())
    }
    
    /// Önbellekteki sonucu getir, süresi geçmişse nil döner
    private func getCachedResult(for key: String) -> Any? {
        guard let cachedData = cache[key],
              Date().timeIntervalSince(cachedData.timestamp) < cacheDuration else {
            return nil
        }
        
        return cachedData.data
    }
    
    /// Önbelleği temizle
    func clearCache() {
        cache.removeAll()
    }
    
    // MARK: - Combine Methods
    
    /// API çağrısı yapma
    private func search(query: String, maxResults: Int = 5) -> AnyPublisher<GoogleBooksResponse, Error> {
        let queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "maxResults", value: "\(maxResults)"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        var urlComponents = URLComponents(string: baseURL)!
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            return Fail(error: NSError(domain: "GoogleBooksService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: GoogleBooksResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - API Response Models

struct GoogleBooksResponse: Decodable {
    let kind: String?
    let totalItems: Int?
    let items: [VolumeItem]?
}

struct VolumeItem: Decodable {
    let id: String?
    let selfLink: String?
    let volumeInfo: VolumeInfo
}

struct VolumeInfo: Decodable {
    let title: String?
    let subtitle: String?
    let authors: [String]?
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let industryIdentifiers: [IndustryIdentifier]?
    let pageCount: Int?
    let categories: [String]?
    let averageRating: Double?
    let ratingsCount: Int?
    let imageLinks: ImageLinks?
    let language: String?
    let previewLink: String?
    let infoLink: String?
    let canonicalVolumeLink: String?
}

struct IndustryIdentifier: Decodable {
    let type: String
    let identifier: String
}

struct ImageLinks: Decodable {
    let smallThumbnail: String?
    let thumbnail: String?
    let small: String?
    let medium: String?
    let large: String?
    let extraLarge: String?
} 