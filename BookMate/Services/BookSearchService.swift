import Foundation
import Combine
import Network

class BookSearchService {
    private let baseURL = "https://www.googleapis.com/books/v1/volumes"
    private let networkMonitor = NWPathMonitor()
    private var isNetworkAvailable = true
    private let maxRetryAttempts = 3
    
    init() {
        // Set up network monitoring
        startNetworkMonitoring()
    }
    
    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            self?.isNetworkAvailable = path.status == .satisfied
            print("BookSearchService: Network status changed - Available: \(path.status == .satisfied)")
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        networkMonitor.start(queue: queue)
    }
    
    func searchBooks(query: String) -> AnyPublisher<[BookSearchResult], Error> {
        // Check network availability first
        guard isNetworkAvailable else {
            print("BookSearchService: Network connection unavailable")
            return Fail(error: NSError(domain: "BookSearchService", code: -1009, 
                                      userInfo: [NSLocalizedDescriptionKey: "Bağlantı hatası: The network connection was lost."]))
                .eraseToAnyPublisher()
        }
        
        // URL'i oluştur, URL encoding işlemleri
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)?q=\(encodedQuery)&maxResults=20") else {
            print("BookSearchService: URL oluşturma hatası")
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        print("BookSearchService: API isteği yapılıyor: \(url.absoluteString)")
        
        // Configure URL session with timeout settings
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15 // 15 seconds timeout
        config.waitsForConnectivity = true
        let session = URLSession(configuration: config)
        
        // API isteği with retry logic
        return requestWithRetry(session: session, url: url, retryCount: 0)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    private func requestWithRetry(session: URLSession, url: URL, retryCount: Int) -> AnyPublisher<[BookSearchResult], Error> {
        return session.dataTaskPublisher(for: url)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("BookSearchService: Geçersiz HTTP yanıtı")
                    throw URLError(.badServerResponse)
                }
                
                if httpResponse.statusCode != 200 {
                    print("BookSearchService: HTTP hata kodu: \(httpResponse.statusCode)")
                    throw URLError(.badServerResponse)
                }
                
                print("BookSearchService: Veri alındı, boyut: \(data.count) bytes")
                return data
            }
            .decode(type: GoogleBooksResponse.self, decoder: JSONDecoder())
            .map { response in
                // Alınan verileri dönüştür
                guard let items = response.items else {
                    print("BookSearchService: Sonuç bulunamadı veya boş yanıt")
                    return []
                }
                
                let results = items.compactMap { item -> BookSearchResult? in
                    guard let volumeInfo = item.volumeInfo,
                          let title = volumeInfo.title else {
                        return nil
                    }
                    
                    let authors = volumeInfo.authors?.joined(separator: ", ") ?? "Bilinmeyen Yazar"
                    
                    print("BookSearchService: Kitap bulundu: \(title) - \(authors)")
                    
                    return BookSearchResult(
                        title: title,
                        author: authors,
                        coverUrl: volumeInfo.imageLinks?.thumbnail,
                        pageCount: volumeInfo.pageCount ?? 0,
                        genre: volumeInfo.categories?.first ?? "",
                        summary: volumeInfo.description ?? ""
                    )
                }
                
                print("BookSearchService: Toplam \(results.count) kitap bulundu")
                return results
            }
            .catch { [weak self] error -> AnyPublisher<[BookSearchResult], Error> in
                guard let self = self, retryCount < self.maxRetryAttempts else {
                    // Max retries reached, return the error
                    if error is URLError, (error as? URLError)?.code == .notConnectedToInternet {
                        return Fail(error: NSError(domain: "BookSearchService", code: -1009, 
                                                  userInfo: [NSLocalizedDescriptionKey: "Bağlantı hatası: The network connection was lost."]))
                                .eraseToAnyPublisher()
                    }
                    return Fail(error: error).eraseToAnyPublisher()
                }
                
                // Only retry for network-related errors
                if let urlError = error as? URLError, 
                   [.notConnectedToInternet, .networkConnectionLost, .timedOut].contains(urlError.code) {
                    print("BookSearchService: Network error, retrying (\(retryCount + 1)/\(self.maxRetryAttempts))")
                    
                    // Add delay before retry (exponential backoff)
                    let delay = TimeInterval(pow(2.0, Double(retryCount))) * 0.5
                    return Just(())
                        .delay(for: .seconds(delay), scheduler: DispatchQueue.global())
                        .flatMap { [weak self] _ -> AnyPublisher<[BookSearchResult], Error> in
                            guard let self = self else {
                                return Fail(error: URLError(.unknown)).eraseToAnyPublisher()
                            }
                            return self.requestWithRetry(session: session, url: url, retryCount: retryCount + 1)
                        }
                        .eraseToAnyPublisher()
                }
                
                // For other errors, don't retry
                return Fail(error: error).eraseToAnyPublisher()
            }
    }
    
    // ISBN ile kitap arama
    func searchBookByISBN(isbn: String) -> AnyPublisher<BookSearchResult?, Error> {
        print("BookSearchService: ISBN araması: \(isbn)")
        return searchBooks(query: "isbn:\(isbn)")
            .map { results in
                let result = results.first
                print("BookSearchService: ISBN araması sonucu: \(result != nil ? "Bulundu" : "Bulunamadı")")
                return result
            }
            .eraseToAnyPublisher()
    }
    
    deinit {
        networkMonitor.cancel()
    }
}

// Google Books API yanıt modelleri
struct GoogleBooksResponse: Codable {
    let items: [GoogleBookItem]?
    let totalItems: Int?
    let kind: String?
}

struct GoogleBookItem: Codable {
    let id: String?
    let volumeInfo: VolumeInfo?
}

struct VolumeInfo: Codable {
    let title: String?
    let authors: [String]?
    let description: String?
    let pageCount: Int?
    let categories: [String]?
    let imageLinks: ImageLinks?
    let publisher: String?
    let publishedDate: String?
    let language: String?
    let industryIdentifiers: [IndustryIdentifier]?
}

struct IndustryIdentifier: Codable {
    let type: String?
    let identifier: String?
}

struct ImageLinks: Codable {
    let smallThumbnail: String?
    let thumbnail: String?
    
    // Google Books API görsel URL'leri HTTP olarak döndürüldüğünde HTTPS'e dönüştürme
    func getThumbnailHttps() -> String? {
        guard let url = thumbnail else { return nil }
        return url.replacingOccurrences(of: "http://", with: "https://")
    }
}

// Mock servis, test ve geliştirme için
class MockBookSearchService {
    func searchBooks(query: String) -> AnyPublisher<[BookSearchResult], Error> {
        // Örnek arama sonuçları
        let results = [
            BookSearchResult(
                title: "Suç ve Ceza",
                author: "Fyodor Dostoyevski",
                coverUrl: nil,
                pageCount: 671,
                genre: "Klasik",
                summary: "Raskolnikov'un işlediği cinayet sonrası yaşadığı vicdani sorgulamaları anlatır."
            ),
            BookSearchResult(
                title: "1984",
                author: "George Orwell",
                coverUrl: nil,
                pageCount: 328,
                genre: "Distopya",
                summary: "Büyük Birader sizi izliyor. Totaliter bir distopya romanı."
            ),
            BookSearchResult(
                title: "Dönüşüm",
                author: "Franz Kafka",
                coverUrl: nil,
                pageCount: 160,
                genre: "Roman",
                summary: "Gregor Samsa bir sabah kendini dev bir böceğe dönüşmüş olarak bulur."
            )
        ]
        
        // Arama terimini içeren kitapları filtrele
        let filteredResults = results.filter { result in
            result.title.lowercased().contains(query.lowercased()) ||
            result.author.lowercased().contains(query.lowercased())
        }
        
        print("MockBookSearchService: '\(query)' için \(filteredResults.count) sonuç bulundu")
        
        // Asenkron işlemi simule et
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                promise(.success(filteredResults))
            }
        }.eraseToAnyPublisher()
    }
}

// Book arama sonucu modeli
struct BookSearchResult: Identifiable {
    let id = UUID()
    let title: String
    let author: String
    let coverUrl: String?
    let pageCount: Int
    let genre: String
    let summary: String
} 