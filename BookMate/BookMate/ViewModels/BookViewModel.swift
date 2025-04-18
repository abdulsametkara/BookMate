import Foundation
import Combine

class BookViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var userLibrary: [Book] = []
    @Published var currentlyReadingBooks: [Book] = []
    @Published var recentlyAddedBooks: [Book] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    init() {
        loadSampleBooks()
    }
    
    private func loadSampleBooks() {
        let sampleBook1 = Book(
            id: UUID().uuidString,
            isbn: "9780451524935",
            title: "1984",
            subtitle: "Distopik Roman",
            authors: ["George Orwell"],
            publisher: "Signet Classic",
            publishedDate: nil,
            description: "Öncü distopik bir roman, totaliter bir hükümetin kontrol ettiği bir toplumu anlatır.",
            pageCount: 328,
            categories: ["Kurgu", "Klasikler", "Distopya"],
            imageLinks: BookImageLinks(thumbnail: "https://covers.openlibrary.org/b/id/8231579-M.jpg", 
                                      large: "https://covers.openlibrary.org/b/id/8231579-L.jpg"),
            language: "tr",
            dateAdded: Date(),
            startedReading: Date().addingTimeInterval(-30*24*60*60),
            finishedReading: nil,
            currentPage: 156,
            readingStatus: .inProgress,
            isFavorite: true,
            userRating: 4.7,
            userNotes: "Bu kitabı eşimle birlikte okuyoruz, harika bir deneyim.",
            readingTime: 1240*60,
            lastReadingSession: Date().addingTimeInterval(-2*24*60*60),
            recommendedBy: nil,
            recommendedDate: nil,
            partnerNotes: nil
        )
        
        let sampleBook2 = Book(
            id: UUID().uuidString,
            isbn: "9780140283334",
            title: "Suç ve Ceza",
            subtitle: "Psikolojik Roman",
            authors: ["Fyodor Dostoyevski"],
            publisher: "Penguin Classics",
            publishedDate: nil,
            description: "Raskolnikov adlı bir öğrencinin psikolojik ve ahlaki çatışmalarını anlatan klasik bir roman.",
            pageCount: 671,
            categories: ["Klasikler", "Kurgu", "Psikolojik"],
            imageLinks: BookImageLinks(thumbnail: "https://covers.openlibrary.org/b/id/8412383-M.jpg", 
                                      large: "https://covers.openlibrary.org/b/id/8412383-L.jpg"),
            language: "tr",
            dateAdded: Date().addingTimeInterval(-60*24*60*60),
            startedReading: Date().addingTimeInterval(-50*24*60*60),
            finishedReading: Date().addingTimeInterval(-5*24*60*60),
            currentPage: 671,
            readingStatus: .finished,
            isFavorite: true,
            userRating: 5.0,
            userNotes: "Şimdiye kadar okuduğum en etkileyici kitaplardan biri.",
            readingTime: 3600*60,
            lastReadingSession: Date().addingTimeInterval(-5*24*60*60),
            recommendedBy: nil,
            recommendedDate: nil,
            partnerNotes: nil
        )
        
        let sampleBook3 = Book(
            id: UUID().uuidString,
            isbn: "9780316219266",
            title: "İkigai: Japonların Uzun ve Mutlu Yaşam Sırrı",
            subtitle: "Kişisel Gelişim",
            authors: ["Hector Garcia", "Francesc Miralles"],
            publisher: "Penguin Life",
            publishedDate: nil,
            description: "Japonların mutlu ve anlamlı bir yaşam sürmek için kullandıkları ikigai kavramını anlatan kitap.",
            pageCount: 208,
            categories: ["Kişisel Gelişim", "Psikoloji", "Felsefe"],
            imageLinks: BookImageLinks(thumbnail: "https://covers.openlibrary.org/b/id/8231579-M.jpg", 
                                      large: "https://covers.openlibrary.org/b/id/8231579-L.jpg"),
            language: "tr",
            dateAdded: Date().addingTimeInterval(-10*24*60*60),
            startedReading: nil,
            finishedReading: nil,
            currentPage: 0,
            readingStatus: .notStarted,
            isFavorite: false,
            userRating: nil,
            userNotes: nil,
            readingTime: 0,
            lastReadingSession: nil,
            recommendedBy: "Eşim",
            recommendedDate: Date().addingTimeInterval(-10*24*60*60),
            partnerNotes: "Bu kitabı birlikte okuyabiliriz. İçeriği çok ilgi çekici."
        )
        
        books = [sampleBook1, sampleBook2, sampleBook3]
        userLibrary = books
        currentlyReadingBooks = [sampleBook1]
        recentlyAddedBooks = [sampleBook3, sampleBook1, sampleBook2]
    }
} 