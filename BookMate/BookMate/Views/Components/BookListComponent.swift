import SwiftUI

struct BookListComponent: View {
    let books: [Book]
    let title: String
    var showMoreAction: (() -> Void)? = nil
    var onSelectBook: ((Book) -> Void)? = nil
    var emptyStateMessage: String = "Henüz kitap eklenmemiş"
    var isCompact: Bool = false
    var maxItems: Int? = nil
    
    var displayedBooks: [Book] {
        if let maxItems = maxItems, books.count > maxItems {
            return Array(books.prefix(maxItems))
        }
        return books
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Başlık
            if !title.isEmpty {
                HStack {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    if books.count > 0 && showMoreAction != nil {
                        Button(action: {
                            showMoreAction?()
                        }) {
                            Text("Tümünü Gör")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            if books.isEmpty {
                // Boş durum
                VStack(spacing: 12) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text(emptyStateMessage)
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            } else {
                // Kitap Listesi
                LazyVStack(spacing: 12) {
                    ForEach(displayedBooks) { book in
                        BookCardView(book: book, compact: isCompact)
                            .onTapGesture {
                                onSelectBook?(book)
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct BookListComponent_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 24) {
                BookListComponent(
                    books: [
                        Book(
                            id: UUID(),
                            isbn: "12345678",
                            title: "Sherlock Holmes'un Maceraları",
                            authors: ["Arthur Conan Doyle"],
                            description: "Ünlü dedektif Sherlock Holmes'un farklı maceraları.",
                            pageCount: 320,
                            categories: ["Polisiye", "Macera"],
                            imageLinks: nil,
                            publishedDate: "1892",
                            publisher: "Everest Yayınları",
                            language: "tr",
                            readingStatus: .inProgress,
                            readingProgressPercentage: 65
                        ),
                        Book(
                            id: UUID(),
                            isbn: "98765432",
                            title: "Yüzüklerin Efendisi: Yüzük Kardeşliği",
                            authors: ["J.R.R. Tolkien"],
                            description: "Frodo'nun yüzüğü yok etme görevi.",
                            pageCount: 423,
                            categories: ["Fantastik", "Macera"],
                            imageLinks: nil,
                            publishedDate: "1954",
                            publisher: "İthaki Yayınları",
                            language: "tr",
                            readingStatus: .finished,
                            readingProgressPercentage: 100
                        )
                    ],
                    title: "Okuduğum Kitaplar",
                    showMoreAction: {},
                    onSelectBook: { _ in }
                )
                
                BookListComponent(
                    books: [],
                    title: "Okumayı Planladığım Kitaplar",
                    emptyStateMessage: "Henüz okuma listenizde kitap yok"
                )
                
                BookListComponent(
                    books: [
                        Book(
                            id: UUID(),
                            isbn: "45678123",
                            title: "Küçük Prens",
                            authors: ["Antoine de Saint-Exupéry"],
                            description: "Küçük Prens'in gezegen gezegen yolculuğu.",
                            pageCount: 96,
                            categories: ["Çocuk", "Felsefi"],
                            imageLinks: nil,
                            publishedDate: "1943",
                            publisher: "Can Yayınları",
                            language: "tr",
                            readingStatus: .notStarted,
                            readingProgressPercentage: 0
                        )
                    ],
                    title: "Popüler Kitaplar",
                    isCompact: true,
                    maxItems: 1
                )
            }
            .padding(.vertical)
            .background(Color(.systemGray6))
        }
    }
} 