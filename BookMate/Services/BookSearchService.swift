import Foundation
import Combine

class BookSearchService {
    private let baseURL = "https://www.googleapis.com/books/v1/volumes"
    
    func searchBooks(query: String) -> AnyPublisher<[BookSearchResult], Error> {
        // URL'i oluştur, URL encoding işlemleri
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)?q=\(encodedQuery)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        // API isteği
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: GoogleBooksResponse.self, decoder: JSONDecoder())
            .map { response in
                // Alınan verileri dönüştür
                response.items?.compactMap { item -> BookSearchResult? in
                    guard let volumeInfo = item.volumeInfo,
                          let title = volumeInfo.title,
                          let authors = volumeInfo.authors,
                          !authors.isEmpty else {
                        return nil
                    }
                    
                    return BookSearchResult(
                        title: title,
                        author: authors.joined(separator: ", "),
                        coverUrl: volumeInfo.imageLinks?.thumbnail,
                        pageCount: volumeInfo.pageCount ?? 0,
                        genre: volumeInfo.categories?.first ?? "",
                        summary: volumeInfo.description ?? ""
                    )
                } ?? []
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // ISBN ile kitap arama
    func searchBookByISBN(isbn: String) -> AnyPublisher<BookSearchResult?, Error> {
        return searchBooks(query: "isbn:\(isbn)")
            .map { results in
                return results.first
            }
            .eraseToAnyPublisher()
    }
}

// Google Books API yanıt modelleri
struct GoogleBooksResponse: Codable {
    let items: [GoogleBookItem]?
}

struct GoogleBookItem: Codable {
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
}

struct ImageLinks: Codable {
    let smallThumbnail: String?
    let thumbnail: String?
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
        
        // Asenkron işlemi simule et
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                promise(.success(filteredResults))
            }
        }.eraseToAnyPublisher()
    }
} 