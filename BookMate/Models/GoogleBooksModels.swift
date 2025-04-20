import Foundation

// Google Books API yanıt modeli
struct GoogleBooksResponse: Codable {
    let items: [VolumeItem]?
    let totalItems: Int
}

// API'den gelen kitap öğesi modeli
struct VolumeItem: Codable {
    let id: String
    let volumeInfo: VolumeInfo
}

// Kitap detay bilgileri
struct VolumeInfo: Codable {
    let title: String
    let subtitle: String?
    let authors: [String]?
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let pageCount: Int?
    let categories: [String]?
    let averageRating: Double?
    let ratingsCount: Int?
    let imageLinks: ImageLinks?
    let language: String?
    let industryIdentifiers: [IndustryIdentifier]?
}

// ISBN bilgileri
struct IndustryIdentifier: Codable {
    let type: String
    let identifier: String
}

// Kitap kapak resimleri
struct ImageLinks: Codable {
    let smallThumbnail: URL?
    let thumbnail: URL?
}

// ISBN türleri için yardımcı enum
enum ISBNType: String {
    case isbn10 = "ISBN_10"
    case isbn13 = "ISBN_13"
    case other = "OTHER"
} 