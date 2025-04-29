import SwiftUI
import SystemConfiguration
import Network

struct WishlistView: View {
    @EnvironmentObject var bookViewModel: BookViewModel
    @State private var isAddingBook = false
    @State private var searchText = ""
    @State private var searchResults: [GoogleBook] = []
    @State private var isSearching = false
    @State private var errorMessage: String? = nil
    @State private var networkMonitor = NWPathMonitor()
    @State private var isNetworkAvailable = true
    @State private var searchTask: DispatchWorkItem?
    
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
    
    private var filteredWishlist: [GoogleBook] {
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
    let book: GoogleBook
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
    @State private var searchResults: [GoogleBook] = []
    @State private var isSearching = false
    @State private var errorMessage: String? = nil
    @State private var networkMonitor = NWPathMonitor()
    @State private var isNetworkAvailable = true
    @State private var searchTask: DispatchWorkItem?
    
    // Açlık Oyunları örnek kitabı - her zaman çalışması için
    private let sampleHungerGamesBook = GoogleBook(
        id: UUID(),
        isbn: "9780439023481",
        title: "Açlık Oyunları",
        authors: ["Suzanne Collins"],
        description: "Açlık Oyunları, Suzanne Collins tarafından yazılmış distopik bir macera romanıdır.",
        pageCount: 374,
        categories: ["Distopya", "Macera"],
        imageLinks: ImageLinks(small: nil, thumbnail: "https://covers.openlibrary.org/b/isbn/9780439023481-M.jpg", medium: nil, large: nil),
        publishedDate: "2008",
        publisher: "Scholastic Press",
        language: "en",
        readingStatus: .notStarted
    )
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Network status indicator
                if !isNetworkAvailable {
                    HStack {
                        Image(systemName: "wifi.slash")
                            .foregroundColor(.orange)
                        Text("Çevrimdışı mod")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(4)
                    .padding(.horizontal)
                }
                
                // Arama çubuğu
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Kitap adı, yazar veya ISBN ara", text: $searchText)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: searchText) { _, newValue in
                            // Debounce uygula - kullanıcı yazmayı bitirdikten 0.5 saniye sonra ara
                            searchTask?.cancel()
                            
                            let task = DispatchWorkItem {
                                if !newValue.isEmpty && newValue.count > 2 {
                                    searchBooks()
                                }
                            }
                            
                            searchTask = task
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task)
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
                        Image(systemName: error.contains("Bağlantı hatası") ? "wifi.exclamationmark" : "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(error.contains("Bağlantı hatası") ? .orange : .red)
                        
                        Text(error)
                            .font(.headline)
                            .foregroundColor(error.contains("Bağlantı hatası") ? .orange : .red)
                            .multilineTextAlignment(.center)
                        
                        if error.contains("Bağlantı hatası") || error.contains("İnternet") {
                            Button(action: {
                                searchBooks()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Yeniden Dene")
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
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
            .onAppear {
                setupNetworkMonitoring()
            }
            .onDisappear {
                networkMonitor.cancel()
            }
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
    
    private func setupNetworkMonitoring() {
        // Cancel any existing monitor first
        networkMonitor.cancel()
        
        // Create a new monitor
        networkMonitor = NWPathMonitor()
        
        // Set up path update handler
        networkMonitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                let wasAvailable = self.isNetworkAvailable
                self.isNetworkAvailable = path.status == .satisfied
                
                // Ağ bağlantısı varsa ve önceden yoktuysa, ve arama metni doluysa otomatik olarak tekrar ara
                if self.isNetworkAvailable && !wasAvailable && !self.searchText.isEmpty {
                    self.searchBooks()
                }
                
                // If network just became unavailable and we're searching, show error
                if !self.isNetworkAvailable && self.isSearching {
                    self.isSearching = false
                    self.errorMessage = "Bağlantı hatası. İnternet bağlantınızı kontrol edin."
                }
            }
        }
        
        // Start monitoring on a background queue
        let queue = DispatchQueue(label: "NetworkMonitor")
        networkMonitor.start(queue: queue)
        
        // Initialize with current status
        isNetworkAvailable = networkMonitor.currentPath.status == .satisfied
    }
    
    private func searchBooks(forceShowSample: Bool = false) {
        isSearching = true
        errorMessage = nil
        
        // Arama terimini kontrol et ve hazırla
        let searchTerm = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if searchTerm.isEmpty {
            isSearching = false
            errorMessage = "Lütfen bir arama terimi girin"
            return
        }
        
        // OpenLibrary API - daha az kısıtlayıcı ve Google'dan daha güvenilir
        let baseUrl = "https://openlibrary.org/search.json"
        guard var components = URLComponents(string: baseUrl) else {
            isSearching = false
            errorMessage = "URL oluşturulamadı"
            return
        }
        
        // OpenLibrary search parametreleri
        components.queryItems = [
            URLQueryItem(name: "q", value: searchTerm),
            URLQueryItem(name: "limit", value: "20")
        ]
        
        guard let url = components.url else {
            isSearching = false
            errorMessage = "Geçersiz arama terimi"
            return
        }
        
        // Alternatif kitap API'si olarak OpenLibrary kullan
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isSearching = false
                
                if let error = error {
                    self.errorMessage = "Arama yapılırken bir hata oluştu: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "Veri alınamadı. Lütfen tekrar deneyin."
                    return
                }
                
                do {
                    // OpenLibrary formatını ayrıştır
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let docs = json["docs"] as? [[String: Any]], !docs.isEmpty {
                        
                        var books: [GoogleBook] = []
                        
                        for doc in docs {
                            // Her kitap için gerekli bilgileri çıkar
                            guard let title = doc["title"] as? String else { continue }
                            
                            // Yazar bilgileri farklı anahtar altında olabilir
                            var authors: [String] = []
                            if let authorNames = doc["author_name"] as? [String] {
                                authors = authorNames
                            } else {
                                authors = ["Bilinmeyen Yazar"]
                            }
                            
                            // Cover ID
                            var thumbnailUrl: String? = nil
                            if let coverId = doc["cover_i"] as? Int {
                                thumbnailUrl = "https://covers.openlibrary.org/b/id/\(coverId)-M.jpg"
                            }
                        
                        // ISBN
                        var isbn: String? = nil
                            if let isbns = doc["isbn"] as? [String], !isbns.isEmpty {
                                isbn = isbns[0]
                            }
                            
                            // Yayın tarihi (ilk baskı)
                            var publishedDate: String? = nil
                            if let firstPublishYear = doc["first_publish_year"] as? Int {
                                publishedDate = "\(firstPublishYear)"
                            }
                            
                            // Sayfa sayısı
                            var pageCount: Int? = nil
                            if let pages = doc["number_of_pages_median"] as? Int {
                                pageCount = pages
                            }
                            
                            // Kategoriler
                            var categories: [String]? = nil
                            if let subjects = doc["subject"] as? [String], !subjects.isEmpty {
                                categories = Array(subjects.prefix(5))  // İlk 5 kategori
                            }
                            
                            // Yayıncı
                            var publisher: String? = nil
                            if let publishers = doc["publisher"] as? [String], !publishers.isEmpty {
                                publisher = publishers[0]
                        }
                        
                        // Kitap nesnesi oluştur
                        let book = GoogleBook(
                                id: UUID(),
                            isbn: isbn,
                            title: title,
                            authors: authors,
                                description: nil, // OpenLibrary temel aramada açıklama vermiyor
                                pageCount: pageCount,
                                categories: categories,
                                imageLinks: thumbnailUrl != nil ? ImageLinks(
                                    small: nil,
                                    thumbnail: thumbnailUrl,
                                    medium: nil,
                                    large: nil
                                ) : nil,
                                publishedDate: publishedDate,
                                publisher: publisher,
                                language: doc["language"] as? String,
                                readingStatus: .notStarted
                        )
                        
                        books.append(book)
                    }
                    
                        if !books.isEmpty {
                            self.searchResults = books
                    } else {
                            self.errorMessage = "'\(searchTerm)' için sonuç bulunamadı."
                        }
                    } else {
                        self.errorMessage = "'\(searchTerm)' için sonuç bulunamadı."
                    }
                } catch {
                    self.errorMessage = "Veri işlenemedi. Lütfen tekrar deneyin."
                }
            }
        }
        
        task.resume()
    }
}

// API yanıt modelleri
struct WishlistBookResponse: Codable {
    let items: [WishlistBookItem]?
    let totalItems: Int?
    let kind: String?
    
    // Hata yakalamak için alternatif ayrıştırma yöntemi
    static func parse(data: Data) -> Result<WishlistBookResponse, Error> {
        do {
            // Standard decoding
            let decoder = JSONDecoder()
            let response = try decoder.decode(WishlistBookResponse.self, from: data)
            return .success(response)
        } catch {
            // İlk hata durumunda JSON içeriğini yazdır
            print("JSON Parse Error: \(error.localizedDescription)")
            
            // Raw JSON string olarak yazdır (debug için)
            if let jsonString = String(data: data, encoding: .utf8) {
                print("JSON Parse Error - Raw JSON başlangıç: \(jsonString.prefix(300))...")
            }
            
            // Alternatif olarak daha esnek bir ayrıştırma deneyelim
            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    return .failure(NSError(domain: "BookMateApp", code: 1001, userInfo: [NSLocalizedDescriptionKey: "JSON formatı geçersiz"]))
                }
                
                // items ve totalItems'ı manuel olarak çıkaralım
                let totalItems = json["totalItems"] as? Int
                let kind = json["kind"] as? String
                
                var bookItems: [WishlistBookItem] = []
                
                // items varsa işle
                if let items = json["items"] as? [[String: Any]] {
                    for item in items {
                        if let volumeInfo = item["volumeInfo"] as? [String: Any] {
                            let title = volumeInfo["title"] as? String
                            let authors = volumeInfo["authors"] as? [String]
                            let description = volumeInfo["description"] as? String
                            let pageCount = volumeInfo["pageCount"] as? Int
                            let categories = volumeInfo["categories"] as? [String]
                            let publishedDate = volumeInfo["publishedDate"] as? String
                            let publisher = volumeInfo["publisher"] as? String
                            let language = volumeInfo["language"] as? String
                            
                            // imageLinks'i ayrıştır
                            var imageLinksObj: WishlistImageLinks? = nil
                            if let imageLinks = volumeInfo["imageLinks"] as? [String: Any] {
                                let smallThumbnail = imageLinks["smallThumbnail"] as? String
                                let thumbnail = imageLinks["thumbnail"] as? String
                                imageLinksObj = WishlistImageLinks(
                                    smallThumbnail: smallThumbnail,
                                    thumbnail: thumbnail
                                )
                            }
                            
                            // industryIdentifiers'ı ayrıştır
                            var identifiers: [WishlistIdentifier] = []
                            if let industryIds = volumeInfo["industryIdentifiers"] as? [[String: Any]] {
                                for idInfo in industryIds {
                                    let type = idInfo["type"] as? String
                                    let identifier = idInfo["identifier"] as? String
                                    identifiers.append(WishlistIdentifier(
                                        type: type,
                                        identifier: identifier
                                    ))
                                }
                            }
                            
                            let volumeInfoObj = WishlistVolumeInfo(
                                title: title,
                                authors: authors,
                                description: description,
                                pageCount: pageCount,
                                categories: categories,
                                imageLinks: imageLinksObj,
                                publishedDate: publishedDate,
                                publisher: publisher,
                                language: language,
                                industryIdentifiers: identifiers.isEmpty ? nil : identifiers
                            )
                            
                            let bookItem = WishlistBookItem(volumeInfo: volumeInfoObj)
                            bookItems.append(bookItem)
                        }
                    }
                }
                
                // Yanıt modelini oluştur
                let response = WishlistBookResponse(
                    items: bookItems,
                    totalItems: totalItems,
                    kind: kind
                )
                
                return .success(response)
            } catch {
                print("Alternatif ayrıştırma da başarısız: \(error.localizedDescription)")
                return .failure(error)
            }
        }
    }
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