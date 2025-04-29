// Book.swift modellerine yardımcı extension'lar
import SwiftUI
import Foundation

// Google Books API'den kitap verilerini işlemek için yardımcı extension'lar
extension GoogleBook {
    // Kitap arka plan rengi oluşturmak için yardımcı metod
    static func bookColor(for title: String) -> Color {
        let colors: [Color] = [
            .blue, .purple, .red, .orange, .green, .pink, 
            Color(#colorLiteral(red: 0.1215686277, green: 0.01176470611, blue: 0.4235294163, alpha: 1)),
            Color(#colorLiteral(red: 0.5058823824, green: 0.3372549117, blue: 0.06666667014, alpha: 1)),
            Color(#colorLiteral(red: 0.1215686277, green: 0.01176470611, blue: 0.4235294163, alpha: 1)),
            Color(#colorLiteral(red: 0.521568656, green: 0.1098039225, blue: 0.05098039284, alpha: 1))
        ]
        
        var hash = 0
        for char in title {
            hash = ((hash << 5) &- hash) &+ Int(char.asciiValue ?? 0)
        }
        
        let index = abs(hash) % colors.count
        return colors[index]
    }
    
    // Kitap URL'lerinin HTTPS protokolünü kullanmasını sağlamak için yardımcı metod
    static func secureBookUrl(_ urlString: String) -> String {
        if urlString.hasPrefix("http://") {
            return "https://" + urlString.dropFirst("http://".count)
        }
        return urlString
    }
    
    // Book.swift'teki örneklere ek örnek kitaplar
    static var additionalSamples: [GoogleBook] = [
        GoogleBook(
            id: UUID(),
            isbn: "9789944884068",
            title: "Araba Sevdası",
            authors: ["Recaizade Mahmut Ekrem"],
            description: "Türk edebiyatının önemli eserlerinden biri olan bu roman, 19. yüzyılın sonlarında İstanbul'da geçer ve dönemin sosyal yapısını, batılılaşma hareketlerini eleştirel bir gözle anlatır.",
            pageCount: 240,
            categories: ["Roman", "Türk Edebiyatı"],
            imageLinks: ImageLinks(
                small: nil,
                thumbnail: "https://covers.openlibrary.org/b/id/12860725-M.jpg",
                medium: nil,
                large: nil
            ),
            publishedDate: "1898",
            publisher: "Yapı Kredi Yayınları",
            language: "tr",
            readingStatus: .finished,
            readingProgressPercentage: 100,
            userNotes: "Türk edebiyatının klasiklerinden",
            userRating: 4,
            price: nil,
            currency: nil,
            startedReading: Date().addingTimeInterval(-120*24*60*60),
            finishedReading: Date().addingTimeInterval(-50*24*60*60),
            currentPage: 240,
            lastReadAt: Date().addingTimeInterval(-50*24*60*60)
        ),
        GoogleBook(
            id: UUID(),
            isbn: "9780446310789",
            title: "To Kill a Mockingbird",
            authors: ["Harper Lee"],
            description: "The unforgettable novel of a childhood in a sleepy Southern town and the crisis of conscience that rocked it.",
            pageCount: 336,
            categories: ["Fiction", "Classics"],
            imageLinks: ImageLinks(
                small: nil,
                thumbnail: "https://covers.openlibrary.org/b/id/8314135-M.jpg",
                medium: nil,
                large: nil
            ),
            publishedDate: "1960-07-11",
            publisher: "J.B. Lippincott & Co.",
            language: "en",
            readingStatus: .finished,
            readingProgressPercentage: 100,
            userNotes: "A masterpiece of American literature",
            userRating: 5,
            price: nil,
            currency: nil,
            startedReading: Date().addingTimeInterval(-60*24*60*60),
            finishedReading: Date().addingTimeInterval(-15*24*60*60),
            currentPage: 336,
            lastReadAt: Date().addingTimeInterval(-15*24*60*60)
        )
    ]
    
    // OpenLibrary API'den veri çekmek için yardımcı metod
    static func createFromOpenLibrary(title: String, authors: [String], isbn: String?, coverUrl: String?, publishedDate: String?, pageCount: Int?) -> GoogleBook {
        let book = GoogleBook(
            id: UUID(),
            isbn: isbn,
            title: title,
            authors: authors,
            description: nil, // OpenLibrary API açıklama vermeyebilir
            pageCount: pageCount,
            categories: nil,
            imageLinks: coverUrl != nil ? ImageLinks(
                small: nil,
                thumbnail: coverUrl,
                medium: nil,
                large: nil
            ) : nil,
            publishedDate: publishedDate,
            publisher: nil,
            language: nil,
            readingStatus: .notStarted,
            readingProgressPercentage: 0,
            userNotes: nil,
            userRating: nil,
            price: nil,
            currency: nil,
            startedReading: nil,
            finishedReading: nil,
            currentPage: nil,
            lastReadAt: nil,
            dateAdded: Date()
        )
        
        return book
    }
}

// ReadingStatus için ek özellikler
extension ReadingStatus {
    // Durum için emoji temsilleri
    var emoji: String {
        switch self {
        case .notStarted:
            return "📚"
        case .inProgress:
            return "👓"
        case .finished:
            return "✅"
        }
    }
    
    // Durum renklerini temsilleyen metod
    func stateColor() -> Color {
        switch self {
        case .notStarted:
            return .gray
        case .inProgress:
            return .blue
        case .finished:
            return .green
        }
    }
}

// 3D Kitaplık için kapak oluşturma yardımcısı
extension GoogleBook {
    // 3D kitaplık görünümü için kapak oluştur
    func create3DCover(width: CGFloat = 70, height: CGFloat = 110, isHovered: Bool = false) -> some View {
        let rotationAngle = isHovered ? 15.0 : 5.0
        
        if let url = thumbnailURL {
            return AnyView(
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: width, height: height)
                            .clipped()
                            .cornerRadius(2)
                            .shadow(color: Color.black.opacity(0.4), radius: 2, x: 2, y: 2)
                            .overlay(
                                Rectangle()
                                    .stroke(Color.black.opacity(0.2), lineWidth: 1)
                            )
                            .rotation3DEffect(
                                .degrees(rotationAngle),
                                axis: (x: 0, y: 1, z: 0)
                            )
                    case .empty:
                        ProgressView()
                            .frame(width: width, height: height)
                    case .failure:
                        createDefaultCover(width: width, height: height, rotationAngle: rotationAngle)
                    @unknown default:
                        createDefaultCover(width: width, height: height, rotationAngle: rotationAngle)
                    }
                }
            )
        } else {
            return AnyView(
                createDefaultCover(width: width, height: height, rotationAngle: rotationAngle)
            )
        }
    }
    
    // Varsayılan kapak oluştur
    private func createDefaultCover(width: CGFloat, height: CGFloat, rotationAngle: Double) -> some View {
        ZStack {
            Rectangle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        Self.bookColor(for: title),
                        Self.bookColor(for: title).opacity(0.7)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: width, height: height)
                .cornerRadius(2)
                .shadow(color: Color.black.opacity(0.4), radius: 2, x: 2, y: 2)
                .overlay(
                    Rectangle()
                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                )
                .rotation3DEffect(
                    .degrees(rotationAngle),
                    axis: (x: 0, y: 1, z: 0)
                )
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 10, weight: .medium, design: .serif))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 4)
                
                if !authors.isEmpty {
                    Text(authors.first ?? "")
                        .font(.system(size: 8, weight: .light, design: .serif))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                        .padding(.horizontal, 4)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// OpenLibrary API için yardımcılar 
struct OpenLibrarySearchResponse: Decodable {
    let numFound: Int
    let docs: [OpenLibraryDoc]
    
    struct OpenLibraryDoc: Decodable {
        let key: String?
        let title: String
        let author_name: [String]?
        let isbn: [String]?
        let cover_i: Int?
        let publisher: [String]?
        let publish_date: [String]?
        let number_of_pages_median: Int?
        
        var authors: [String] {
            return author_name ?? ["Yazar Belirtilmemiş"]
        }
        
        var coverUrl: String? {
            if let coverId = cover_i {
                return "https://covers.openlibrary.org/b/id/\(coverId)-M.jpg"
            }
            return nil
        }
        
        var publishedDate: String? {
            return publish_date?.first
        }
        
        func toGoogleBook() -> GoogleBook {
            return GoogleBook.createFromOpenLibrary(
                title: title,
                authors: authors,
                isbn: isbn?.first,
                coverUrl: coverUrl,
                publishedDate: publishedDate,
                pageCount: number_of_pages_median
            )
        }
    }
} 