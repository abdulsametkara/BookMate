import SwiftUI
import Combine

struct SearchView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var bookViewModel: BookViewModel
    
    @State private var searchText = ""
    @State private var searchResults: [Book] = []
    @State private var isSearching = false
    @State private var showAlert = false
    @State private var errorMessage = ""
    
    // Açık initializer ekleyelim
    public init(bookViewModel: BookViewModel) {
        self.bookViewModel = bookViewModel
    }
    
    // Doğrudan BookSearchService kullanmak yerine BookViewModel üzerinden arama yapalım
    private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        NavigationView {
            VStack {
                // Arama başlığı
                searchHeader
                
                // Arama sonuçları
                if isSearching {
                    loadingView
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    emptyResultsView
                } else {
                    searchResultsList
                }
                
                Spacer()
            }
            .navigationTitle("Kitap Ara")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Kapat") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(errorMessage.contains("hata") ? "Hata" : "Bilgi"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("Tamam"))
                )
            }
        }
    }
    
    private var searchHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Kitap adı veya ISBN ara", text: $searchText)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onChange(of: searchText) { _, newValue in
                        if newValue.isEmpty {
                            // Arama temizlendiğinde sonuçları da temizle
                            searchResults = []
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
            
            // Manuel arama butonu
            Button(action: performSearch) {
                Text("Ara")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(searchText.count < 3)
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.5)
            
            Text("Kitaplar aranıyor...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("Sonuç bulunamadı")
                .font(.headline)
            
            Text("Farklı bir arama terimi deneyin")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(searchResults) { book in
                    Button(action: {
                        addBookToLibrary(book)
                    }) {
                        searchResultRow(book)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }
    
    private func searchResultRow(_ book: Book) -> some View {
        HStack(spacing: 15) {
            // Kitap kapağı
            if let imageLinks = book.imageLinks, 
               let thumbnail = imageLinks.thumbnail, 
               !thumbnail.isEmpty,
               let url = URL(string: thumbnail) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if phase.error != nil {
                        bookCoverPlaceholder
                    } else {
                        bookCoverPlaceholder
                            .overlay(ProgressView())
                    }
                }
                .frame(width: 70, height: 100)
                .cornerRadius(8)
                .shadow(radius: 2)
            } else {
                bookCoverPlaceholder
                    .frame(width: 70, height: 100)
            }
            
            // Kitap bilgileri
            VStack(alignment: .leading, spacing: 5) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(book.authorsText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                if let pageCount = book.pageCount, pageCount > 0 {
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
                
                HStack {
                    Spacer()
                    
                    Text("Ekle")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var bookCoverPlaceholder: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .overlay(
                Image(systemName: "book.closed")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.gray)
                    .padding(15)
            )
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        searchResults = []
        
        // Arama terimini temizle ve küçük harfe çevir
        let searchTerm = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        print("Arama terimi: \(searchTerm)")
        
        // Tüm kitapları alıp debug için sayısını loglayalım
        let allBooks = bookViewModel.allBooks
        print("Toplam kitap sayısı: \(allBooks.count)")
        
        // Kitapları daha geniş bir kapsam ve daha esnek bir şekilde filtreleyelim
        let filtered = allBooks.filter { book in
            // Her kitabın içeriğini inceleyelim
            let titleMatch = book.title.lowercased().contains(searchTerm)
            let authorMatch = book.authorsText.lowercased().contains(searchTerm)
            let isbnMatch = book.isbn?.lowercased().contains(searchTerm) ?? false
            let categoryMatch = book.categories?.joined(separator: " ").lowercased().contains(searchTerm) ?? false
            
            if titleMatch {
                print("Başlık eşleşti: \(book.title)")
            }
            if authorMatch {
                print("Yazar eşleşti: \(book.authorsText)")
            }
            
            // Herhangi bir alan eşleşirse true döndür
            return titleMatch || authorMatch || isbnMatch || categoryMatch
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("Arama sonucu: \(filtered.count) kitap bulundu")
            if filtered.isEmpty {
                print("Arama sonucu bulunamadı: \(searchTerm)")
                
                // Mevcut kitapların başlıklarını kontrol edelim
                print("Mevcut kitap başlıkları:")
                for book in allBooks {
                    print("- \(book.title) (Yazarlar: \(book.authorsText))")
                }
            }
            
            // Filtrelenmiş kitapları atayalım
            self.searchResults = filtered
            self.isSearching = false
        }
    }
    
    private func addBookToLibrary(_ book: Book) {
        // Kitabı kütüphaneye ekle
        bookViewModel.addBook(book)
        
        // Başarılı mesajı
        errorMessage = "\(book.title) kitabınıza eklendi."
        showAlert = true
    }
}

// Preview yapılandırması
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(bookViewModel: BookViewModel())
    }
} 