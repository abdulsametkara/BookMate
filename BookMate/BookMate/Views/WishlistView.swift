import SwiftUI

struct WishlistView: View {
    @EnvironmentObject var bookViewModel: BookViewModel
    @State private var isAddingBook = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Arama çubuğu
                SearchBar(text: $searchText, placeholder: "Kitap ara...")
                    .padding(.horizontal)
                
                if filteredWishlist.isEmpty {
                    emptyWishlistView
                } else {
                    wishlistContent
                }
            }
            .navigationTitle("İstek Listem")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isAddingBook = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingBook) {
                AddToWishlistView()
            }
        }
    }
    
    private var filteredWishlist: [Book] {
        if searchText.isEmpty {
            return bookViewModel.wishlistBooks
        } else {
            return bookViewModel.wishlistBooks.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                book.authors.joined(separator: ", ").localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var wishlistContent: some View {
        List {
            ForEach(filteredWishlist) { book in
                WishlistBookRow(book: book)
            }
            .onDelete(perform: removeFromWishlist)
        }
    }
    
    private var emptyWishlistView: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.7))
            
            Text("İstek listenizde henüz kitap yok")
                .font(.headline)
            
            Text("Okumak istediğiniz kitapları buraya ekleyebilirsiniz")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                isAddingBook = true
            }) {
                Text("Kitap Ekle")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func removeFromWishlist(at offsets: IndexSet) {
        for index in offsets {
            let book = filteredWishlist[index]
            bookViewModel.removeFromWishlist(book)
        }
    }
}

struct WishlistBookRow: View {
    let book: Book
    @EnvironmentObject var bookViewModel: BookViewModel
    @State private var showingOptions = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Kitap kapağı
            if let url = book.thumbnailURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 90)
                            .cornerRadius(6)
                    } else {
                        bookCoverPlaceholder
                    }
                }
                .frame(width: 60, height: 90)
            } else {
                bookCoverPlaceholder
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(book.authors.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                if let price = book.price, let currency = book.currency {
                    Text("\(price) \(currency)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(5)
                }
            }
            
            Spacer()
            
            Button(action: {
                showingOptions = true
            }) {
                Image(systemName: "ellipsis")
                    .padding(8)
                    .foregroundColor(.gray)
            }
            .confirmationDialog("Kitap İşlemleri", isPresented: $showingOptions) {
                Button("Kütüphaneye Ekle") {
                    bookViewModel.addToLibrary(book)
                    bookViewModel.removeFromWishlist(book)
                }
                
                Button("Detayları Görüntüle") {
                    // Detay sayfasına git
                }
                
                Button("Silmek İstiyorum", role: .destructive) {
                    bookViewModel.removeFromWishlist(book)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private var bookCoverPlaceholder: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 60, height: 90)
            .overlay(
                Image(systemName: "book.closed")
                    .foregroundColor(.gray)
            )
    }
}

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $text)
                .foregroundColor(.primary)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct AddToWishlistView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var bookViewModel: BookViewModel
    @State private var searchText = ""
    @State private var searchResults: [Book] = []
    @State private var isSearching = false
    @State private var errorMessage: String? = nil
    
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
                                HStack(spacing: 15) {
                                    // Kitap kapağı
                                    Group {
                                        if let imageLinks = book.imageLinks, 
                                           let thumbnail = imageLinks.thumbnail, 
                                           let url = URL(string: thumbnail) {
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
                                        
                                        Text(book.authorsText)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                        
                                        if let pageCount = book.pageCount {
                                            Text("\(pageCount) sayfa")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    // İstek listesine ekle butonu
                                    if bookViewModel.isInWishlist(book) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.system(size: 24))
                                    } else {
                                        Button(action: {
                                            bookViewModel.addToWishlist(book)
                                        }) {
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundColor(.blue)
                                                .font(.system(size: 24))
                                        }
                                    }
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("İstek Listesine Ekle")
            .navigationBarItems(trailing: Button("Kapat") {
                presentationMode.wrappedValue.dismiss()
            })
        }
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
    
    private func searchBooks() {
        isSearching = true
        errorMessage = nil
        
        // Arama terimini temizle
        let searchTerm = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        print("Aranıyor: \(searchTerm)")
        
        // Google Books API URL
        guard let encodedTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://www.googleapis.com/books/v1/volumes?q=\(encodedTerm)&maxResults=20") else {
            isSearching = false
            errorMessage = "Arama sırasında bir hata oluştu"
            return
        }
        
        print("API çağrısı yapılıyor: \(url)")
        
        // API çağrısı
        URLSession.shared.dataTask(with: url) { data, response, error in
            // Ana thread'e dön
            DispatchQueue.main.async {
                self.isSearching = false
                
                // Hata kontrolü
                if let error = error {
                    print("API hatası: \(error.localizedDescription)")
                    self.errorMessage = "Bağlantı hatası: \(error.localizedDescription)"
                    return
                }
                
                // HTTP yanıt kontrolü
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    print("Geçersiz yanıt kodu")
                    self.errorMessage = "Sunucu hatası"
                    return
                }
                
                // Veri kontrolü
                guard let data = data else {
                    print("Veri alınamadı")
                    self.errorMessage = "Veri alınamadı"
                    return
                }
                
                // JSON ayrıştırma
                do {
                    let decoder = JSONDecoder()
                    let result = try decoder.decode(WishlistBookResponse.self, from: data)
                    
                    print("Toplam sonuç: \(result.totalItems ?? 0)")
                    
                    // Sonuçları kitaplara dönüştür
                    let books = result.items?.compactMap { item -> Book? in
                        guard let volumeInfo = item.volumeInfo,
                              let title = volumeInfo.title else {
                            return nil
                        }
                        
                        // Yazarları al veya varsayılan değer ver
                        let authors = volumeInfo.authors ?? ["Yazar Belirtilmemiş"]
                        
                        // ISBN numaralarını al
                        let isbn = volumeInfo.industryIdentifiers?.first(where: { $0.type == "ISBN_13" || $0.type == "ISBN_10" })?.identifier
                        
                        // Kapak görselini al
                        var imageLinks: ImageLinks? = nil
                        if let thumbnail = volumeInfo.imageLinks?.thumbnail {
                            // HTTP bağlantılarını HTTPS'e çevir
                            let secureUrl = thumbnail.replacingOccurrences(of: "http://", with: "https://")
                            imageLinks = ImageLinks(small: nil, thumbnail: secureUrl, medium: nil, large: nil)
                        }
                        
                        return Book(
                            id: UUID(),
                            isbn: isbn,
                            title: title,
                            authors: authors,
                            description: volumeInfo.description,
                            pageCount: volumeInfo.pageCount,
                            categories: volumeInfo.categories,
                            imageLinks: imageLinks,
                            publishedDate: volumeInfo.publishedDate,
                            publisher: volumeInfo.publisher,
                            language: volumeInfo.language,
                            readingStatus: .notStarted
                        )
                    } ?? []
                    
                    self.searchResults = books
                    
                    if books.isEmpty {
                        print("Sonuç bulunamadı")
                    } else {
                        print("\(books.count) kitap bulundu")
                        // İlk 3 kitabın başlığını yazdır
                        for book in books.prefix(3) {
                            print("- \(book.title) by \(book.authorsText)")
                        }
                    }
                } catch {
                    print("JSON ayrıştırma hatası: \(error)")
                    self.errorMessage = "Arama sonuçları işlenemedi"
                }
            }
        }.resume()
    }
}

// API yanıt modelleri
struct WishlistBookResponse: Codable {
    let items: [WishlistBookItem]?
    let totalItems: Int?
}

struct WishlistBookItem: Codable {
    let volumeInfo: WishlistVolumeInfo?
}

struct WishlistVolumeInfo: Codable {
    let title: String?
    let authors: [String]?
    let description: String?
    let pageCount: Int?
    let categories: [String]?
    let imageLinks: WishlistImageLinks?
    let publishedDate: String?
    let publisher: String?
    let language: String?
    let industryIdentifiers: [WishlistIdentifier]?
}

struct WishlistIdentifier: Codable {
    let type: String?
    let identifier: String?
}

struct WishlistImageLinks: Codable {
    let smallThumbnail: String?
    let thumbnail: String?
}

#Preview {
    let bookVM = BookViewModel()
    return WishlistView()
        .environmentObject(bookVM)
} 