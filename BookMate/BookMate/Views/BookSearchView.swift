import SwiftUI

struct BookSearchView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var bookViewModel: BookViewModel
    
    @State private var searchText = ""
    @State private var searchResults: [BookSearchResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String? = nil
    @State private var showingActionSheet = false
    @State private var selectedBook: BookSearchResult? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Arama çubuğu
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Kitap adı, yazar veya ISBN ara", text: $searchText)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onSubmit {
                            if !searchText.isEmpty {
                                searchBooks()
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top)
                
                // Ara butonu
                Button(action: {
                    if !searchText.isEmpty {
                        searchBooks()
                    }
                }) {
                    Text("Ara")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(searchText.isEmpty)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Sonuçlar veya durum göstergeleri
                if isSearching {
                    Spacer()
                    ProgressView("Kitaplar aranıyor...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        Text(error)
                            .font(.headline)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("Sonuç bulunamadı")
                            .font(.headline)
                        Text("Farklı arama terimleri deneyebilirsiniz.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else {
                    // Arama sonuçları
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(searchResults) { book in
                                BookResultRow(book: book)
                                    .onTapGesture {
                                        selectedBook = book
                                        showingActionSheet = true
                                    }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Kitap Ara")
            .navigationBarItems(leading: Button("Kapat") {
                presentationMode.wrappedValue.dismiss()
            })
            .confirmationDialog(
                selectedBook?.title ?? "Kitap Seçenekleri",
                isPresented: $showingActionSheet,
                titleVisibility: .visible
            ) {
                if let book = selectedBook {
                    Button("Kütüphaneye Ekle") {
                        addToLibrary(book)
                    }
                    
                    Button("İstek Listesine Ekle") {
                        addToWishlist(book)
                    }
                    
                    Button("İptal", role: .cancel) { }
                }
            }
        }
    }
    
    private func searchBooks() {
        isSearching = true
        errorMessage = nil
        
        // Arama terimini temizle
        let searchTerm = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Google Books API URL
        guard let encodedTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://www.googleapis.com/books/v1/volumes?q=\(encodedTerm)&maxResults=20") else {
            isSearching = false
            errorMessage = "Arama sırasında bir hata oluştu"
            return
        }
        
        // API çağrısı
        URLSession.shared.dataTask(with: url) { data, response, error in
            // Ana thread'e dön
            DispatchQueue.main.async {
                self.isSearching = false
                
                // Hata kontrolü
                if let error = error {
                    self.errorMessage = "Bağlantı hatası: \(error.localizedDescription)"
                    return
                }
                
                // HTTP yanıt kontrolü
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    self.errorMessage = "Sunucu hatası"
                    return
                }
                
                // Veri kontrolü
                guard let data = data else {
                    self.errorMessage = "Veri alınamadı"
                    return
                }
                
                // JSON ayrıştırma
                do {
                    let decoder = JSONDecoder()
                    let result = try decoder.decode(BookSearchResponse.self, from: data)
                    
                    // Sonuçları kitaplara dönüştür
                    let books = result.items?.compactMap { item in
                        return BookSearchResult.fromSearchItem(item)
                    } ?? []
                    
                    self.searchResults = books
                    
                } catch {
                    self.errorMessage = "Arama sonuçları işlenemedi"
                    print("JSON ayrıştırma hatası: \(error)")
                }
            }
        }.resume()
    }
    
    private func addToLibrary(_ bookResult: BookSearchResult) {
        // BookResult'ı Book modeline dönüştür
        let book = bookResult.toBook()
        
        // Kitabı kütüphaneye ekle
        bookViewModel.addBook(book)
        
        // Başarı mesajı
        errorMessage = "\(bookResult.title) kitabınıza eklendi"
    }
    
    private func addToWishlist(_ bookResult: BookSearchResult) {
        // BookResult'ı Book modeline dönüştür
        let book = bookResult.toBook()
        
        // Kitabı istek listesine ekle
        bookViewModel.addToWishlist(book)
        
        // Başarı mesajı
        errorMessage = "\(bookResult.title) istek listenize eklendi"
    }
}

struct BookResultRow: View {
    let book: BookSearchResult
    
    var body: some View {
        HStack(spacing: 15) {
            // Kitap kapağı
            Group {
                if let coverUrl = book.coverUrl, let url = URL(string: coverUrl) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            bookCoverPlaceholder
                        }
                    }
                } else {
                    bookCoverPlaceholder
                }
            }
            .frame(width: 60, height: 90)
            .cornerRadius(6)
            
            // Kitap bilgileri
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(book.authors.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                if let pageCount = book.pageCount {
                    Text("\(pageCount) sayfa")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let categories = book.categories, !categories.isEmpty {
                    Text(categories.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var bookCoverPlaceholder: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .overlay(
                Image(systemName: "book.closed")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.gray)
                    .padding(12)
            )
    }
}

// Arama sonuçları için model
struct BookSearchResult: Identifiable {
    let id: String
    let title: String
    let authors: [String]
    let description: String?
    let coverUrl: String?
    let pageCount: Int?
    let categories: [String]?
    let publishedDate: String?
    let publisher: String?
    let isbn: String?
    
    // Book modeline dönüştürme
    func toBook() -> Book {
        var imageLinks: ImageLinks? = nil
        if let coverUrl = coverUrl {
            imageLinks = ImageLinks(small: nil, thumbnail: coverUrl, medium: nil, large: nil)
        }
        
        return Book(
            id: UUID(),
            isbn: isbn,
            title: title,
            authors: authors,
            description: description,
            pageCount: pageCount,
            categories: categories,
            imageLinks: imageLinks,
            publishedDate: publishedDate,
            publisher: publisher,
            language: "tr", // Varsayılan dil
            readingStatus: .notStarted
        )
    }
    
    // Google Books API yanıtından oluşturma
    static func fromSearchItem(_ item: BookSearchItem) -> BookSearchResult? {
        guard let volumeInfo = item.volumeInfo,
              let title = volumeInfo.title else {
            return nil
        }
        
        // Yazarları al veya varsayılan değer ver
        let authors = volumeInfo.authors ?? ["Yazar Belirtilmemiş"]
        
        // ISBN numaralarını al
        let isbn = volumeInfo.industryIdentifiers?.first(where: { 
            $0.type == "ISBN_13" || $0.type == "ISBN_10" 
        })?.identifier
        
        return BookSearchResult(
            id: item.id ?? UUID().uuidString,
            title: title,
            authors: authors,
            description: volumeInfo.description,
            coverUrl: volumeInfo.imageLinks?.thumbnail?.replacingOccurrences(of: "http://", with: "https://"),
            pageCount: volumeInfo.pageCount,
            categories: volumeInfo.categories,
            publishedDate: volumeInfo.publishedDate,
            publisher: volumeInfo.publisher,
            isbn: isbn
        )
    }
}

// API yanıt modelleri
struct BookSearchResponse: Codable {
    let items: [BookSearchItem]?
    let totalItems: Int?
    let kind: String?
}

struct BookSearchItem: Codable {
    let id: String?
    let volumeInfo: BookSearchVolumeInfo?
}

struct BookSearchVolumeInfo: Codable {
    let title: String?
    let authors: [String]?
    let description: String?
    let pageCount: Int?
    let categories: [String]?
    let imageLinks: BookSearchImageLinks?
    let publishedDate: String?
    let publisher: String?
    let language: String?
    let industryIdentifiers: [BookSearchIdentifier]?
}

struct BookSearchIdentifier: Codable {
    let type: String?
    let identifier: String?
}

struct BookSearchImageLinks: Codable {
    let smallThumbnail: String?
    let thumbnail: String?
}

struct BookSearchView_Previews: PreviewProvider {
    static var previews: some View {
        BookSearchView()
            .environmentObject(BookViewModel())
    }
} 