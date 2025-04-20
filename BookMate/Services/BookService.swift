import Foundation

class BookService {
    // Singleton instance
    static let shared = BookService()
    
    private let baseURL = "https://www.googleapis.com/books/v1/volumes"
    private var apiKey: String {
        // Gerçek uygulamada bu değer Info.plist'ten veya başka bir güvenli kaynaktan alınmalı
        return ProcessInfo.processInfo.environment["GOOGLE_BOOKS_API_KEY"] ?? "AIzaSyD_kV7iUD5TsUwPcJn-Sc1_RaIEK1sQxjk"
    }
    
    private init() {
        print("BookService başlatıldı. API erişimi hazır.")
    }
    
    // Kitap aramak için
    func searchBooks(query: String) async throws -> [BookSearchResult] {
        // URL oluşturma
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "maxResults", value: "20"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components?.url else {
            throw NSError(domain: "BookService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Geçersiz URL"])
        }
        
        // API isteği
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "BookService", code: 1, userInfo: [NSLocalizedDescriptionKey: "API yanıtı başarısız oldu"])
        }
        
        // JSON'u ayrıştırma
        let searchResponse = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
        
        guard let items = searchResponse.items else {
            return []
        }
        
        // Cache'leme işlemi
        Task {
            try await cacheSearchResults(items)
        }
        
        // BookSearchResult modellerine dönüştürme
        return items.compactMap { volume in
            guard let volumeInfo = volume.volumeInfo else { return nil }
            
            return BookSearchResult(
                id: volume.id ?? UUID().uuidString,
                title: volumeInfo.title ?? "Başlık Yok",
                authors: volumeInfo.authors ?? ["Yazar Belirtilmemiş"],
                publisher: volumeInfo.publisher,
                publishedDate: volumeInfo.publishedDate,
                description: volumeInfo.description,
                pageCount: volumeInfo.pageCount ?? 0,
                categories: volumeInfo.categories ?? [],
                imageLinks: volumeInfo.imageLinks,
                isbn: extractISBN(from: volumeInfo.industryIdentifiers)
            )
        }
    }
    
    // ISBN ile kitap aramak için
    func searchBookByISBN(isbn: String) async throws -> BookSearchResult? {
        // ISBN formatını temizleme
        let cleanISBN = isbn.replacingOccurrences(of: "-", with: "")
        
        // Önce cache'de kontrol et
        if let cachedResult = checkCache(for: cleanISBN) {
            return cachedResult
        }
        
        // URL oluşturma
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "q", value: "isbn:\(cleanISBN)"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = components?.url else {
            throw NSError(domain: "BookService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Geçersiz URL"])
        }
        
        // API isteği
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "BookService", code: 1, userInfo: [NSLocalizedDescriptionKey: "API yanıtı başarısız oldu"])
        }
        
        // JSON'u ayrıştırma
        let searchResponse = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
        
        guard let items = searchResponse.items, let firstItem = items.first, let volumeInfo = firstItem.volumeInfo else {
            return nil
        }
        
        // Cache'leme işlemi
        Task {
            try await cacheSearchResults([firstItem])
        }
        
        // BookSearchResult modeline dönüştürme
        return BookSearchResult(
            id: firstItem.id ?? UUID().uuidString,
            title: volumeInfo.title ?? "Başlık Yok",
            authors: volumeInfo.authors ?? ["Yazar Belirtilmemiş"],
            publisher: volumeInfo.publisher,
            publishedDate: volumeInfo.publishedDate,
            description: volumeInfo.description,
            pageCount: volumeInfo.pageCount ?? 0,
            categories: volumeInfo.categories ?? [],
            imageLinks: volumeInfo.imageLinks,
            isbn: extractISBN(from: volumeInfo.industryIdentifiers)
        )
    }
    
    // Kitap arama sonucunu Book modeline dönüştürme
    func convertToBook(from searchResult: BookSearchResult) -> Book {
        // ISBN ve kapak URL oluşturma
        let coverURL = searchResult.imageLinks?.thumbnail != nil ? URL(string: searchResult.imageLinks!.thumbnail!) : nil
        
        return Book(
            id: UUID().uuidString,
            title: searchResult.title,
            author: searchResult.authors.joined(separator: ", "),
            coverURL: coverURL,
            isbn: searchResult.isbn,
            pageCount: searchResult.pageCount,
            currentPage: 0,
            dateAdded: Date(),
            dateFinished: nil,
            genre: searchResult.categories.first,
            notes: nil,
            isFavorite: false,
            rating: nil
        )
    }
    
    // MARK: - Cache İşlemleri
    
    private func cacheSearchResults(_ items: [Volume]) async throws {
        // UserDefaults'a kaydetme (gerçek uygulamada Core Data veya başka bir kalıcı depolama kullanılmalı)
        let encoder = JSONEncoder()
        let data = try encoder.encode(items)
        
        let timestamp = Date().timeIntervalSince1970
        
        var cachedItems = UserDefaults.standard.dictionary(forKey: "BookSearchCache") as? [String: Any] ?? [:]
        
        for item in items {
            if let id = item.id, let isbn = extractISBN(from: item.volumeInfo?.industryIdentifiers) {
                cachedItems[isbn] = ["data": data, "timestamp": timestamp]
            }
        }
        
        UserDefaults.standard.set(cachedItems, forKey: "BookSearchCache")
    }
    
    private func checkCache(for isbn: String) -> BookSearchResult? {
        guard let cachedItems = UserDefaults.standard.dictionary(forKey: "BookSearchCache") as? [String: Any],
              let itemCache = cachedItems[isbn] as? [String: Any],
              let data = itemCache["data"] as? Data,
              let timestamp = itemCache["timestamp"] as? TimeInterval else {
            return nil
        }
        
        // Cache'in 7 günden eski olup olmadığını kontrol et
        let now = Date().timeIntervalSince1970
        let cacheAge = now - timestamp
        
        if cacheAge > 7 * 24 * 3600 { // 7 gün
            return nil // Cache süresi doldu
        }
        
        do {
            let decoder = JSONDecoder()
            let volumes = try decoder.decode([Volume].self, from: data)
            
            if let firstVolume = volumes.first, let volumeInfo = firstVolume.volumeInfo {
                return BookSearchResult(
                    id: firstVolume.id ?? UUID().uuidString,
                    title: volumeInfo.title ?? "Başlık Yok",
                    authors: volumeInfo.authors ?? ["Yazar Belirtilmemiş"],
                    publisher: volumeInfo.publisher,
                    publishedDate: volumeInfo.publishedDate,
                    description: volumeInfo.description,
                    pageCount: volumeInfo.pageCount ?? 0,
                    categories: volumeInfo.categories ?? [],
                    imageLinks: volumeInfo.imageLinks,
                    isbn: extractISBN(from: volumeInfo.industryIdentifiers)
                )
            }
        } catch {
            print("Cache okuma hatası: \(error)")
        }
        
        return nil
    }
    
    // Industry identifiers'dan ISBN çıkarma
    private func extractISBN(from identifiers: [IndustryIdentifier]?) -> String? {
        guard let identifiers = identifiers else { return nil }
        
        // Önce ISBN_13'e bakalım
        if let isbn13 = identifiers.first(where: { $0.type == "ISBN_13" }) {
            return isbn13.identifier
        }
        
        // Yoksa ISBN_10'u kullanalım
        if let isbn10 = identifiers.first(where: { $0.type == "ISBN_10" }) {
            return isbn10.identifier
        }
        
        return nil
    }
}

// MARK: - API Cevap Modelleri

struct GoogleBooksResponse: Codable {
    let kind: String?
    let totalItems: Int?
    let items: [Volume]?
}

struct Volume: Codable {
    let kind: String?
    let id: String?
    let etag: String?
    let selfLink: String?
    let volumeInfo: VolumeInfo?
}

struct VolumeInfo: Codable {
    let title: String?
    let subtitle: String?
    let authors: [String]?
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let industryIdentifiers: [IndustryIdentifier]?
    let pageCount: Int?
    let categories: [String]?
    let imageLinks: ImageLinks?
    let language: String?
    let previewLink: String?
    let infoLink: String?
}

struct IndustryIdentifier: Codable {
    let type: String
    let identifier: String
}

struct ImageLinks: Codable {
    let smallThumbnail: String?
    let thumbnail: String?
}

// Arama sonucunu daha kolay yönetmek için model
struct BookSearchResult {
    let id: String
    let title: String
    let authors: [String]
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let pageCount: Int
    let categories: [String]
    let imageLinks: ImageLinks?
    let isbn: String?
} 