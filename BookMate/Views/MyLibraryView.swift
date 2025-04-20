import SwiftUI

struct MyLibraryView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var searchText = ""
    @State private var selectedFilter: BookFilter = .all
    @State private var selectedSortOrder: BookSortOrder = .title
    @State private var showAddBookSheet = false
    @State private var books: [Book] = []
    @State private var showBookshelfView = false
    
    // Demo veriler (gerçek uygulamada Firebase'den çekilir)
    let demoBooks = [
        Book(id: "1", title: "Dune", author: "Frank Herbert", coverURL: nil, isbn: "9780441172719", pageCount: 412, currentPage: 200, dateAdded: Date(), dateFinished: nil, genre: "Bilim Kurgu", notes: nil, isFavorite: true, rating: nil),
        Book(id: "2", title: "1984", author: "George Orwell", coverURL: nil, isbn: "9780451524935", pageCount: 328, currentPage: 100, dateAdded: Date(), dateFinished: nil, genre: "Distopya", notes: nil, isFavorite: false, rating: nil),
        Book(id: "3", title: "Sapiens", author: "Yuval Noah Harari", coverURL: nil, isbn: "9780062316097", pageCount: 443, currentPage: 443, dateAdded: Date(), dateFinished: Date(), genre: "Tarih", notes: "Mükemmel bir kitap!", isFavorite: true, rating: 5),
        Book(id: "4", title: "Suç ve Ceza", author: "Fyodor Dostoyevski", coverURL: nil, isbn: "9780143107637", pageCount: 671, currentPage: 671, dateAdded: Date(), dateFinished: Date(), genre: "Klasik", notes: nil, isFavorite: true, rating: 4),
        Book(id: "5", title: "Harry Potter ve Felsefe Taşı", author: "J.K. Rowling", coverURL: nil, isbn: "9781408855652", pageCount: 352, currentPage: 352, dateAdded: Date(), dateFinished: Date(), genre: "Fantastik", notes: nil, isFavorite: true, rating: 5),
        Book(id: "6", title: "Yüzüklerin Efendisi", author: "J.R.R. Tolkien", coverURL: nil, isbn: "9780618640157", pageCount: 1137, currentPage: 400, dateAdded: Date(), dateFinished: nil, genre: "Fantastik", notes: nil, isFavorite: true, rating: nil)
    ]
    
    // Filtrelere göre kitapları getir
    var filteredBooks: [Book] {
        var result = books
        
        // Arama filtrelemesi
        if !searchText.isEmpty {
            result = result.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                book.author.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Kategori filtrelemesi
        switch selectedFilter {
        case .all:
            break // Tüm kitaplar
        case .currentlyReading:
            result = result.filter { !$0.isCompleted }
        case .completed:
            result = result.filter { $0.isCompleted }
        case .favorites:
            result = result.filter { $0.isFavorite }
        }
        
        // Sıralama
        switch selectedSortOrder {
        case .title:
            result.sort { $0.title < $1.title }
        case .author:
            result.sort { $0.author < $1.author }
        case .dateAdded:
            result.sort { $0.dateAdded > $1.dateAdded }
        case .dateFinished:
            result.sort { ($0.dateFinished ?? Date.distantPast) > ($1.dateFinished ?? Date.distantPast) }
        case .readingProgress:
            result.sort { $0.readingProgress > $1.readingProgress }
        }
        
        return result
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filtre ve sıralama seçenekleri
                filterBar
                
                // Kitap listesi
                bookList
            }
            .navigationTitle("Kitaplığım")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddBookSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddBookSheet) {
                AddBookView()
            }
            .sheet(isPresented: $showBookshelfView) {
                BookshelfView()
                    .environmentObject(authViewModel)
            }
            .searchable(text: $searchText, prompt: "Kitap ara")
            .onAppear {
                // Demo verileri yükleme (gerçek uygulamada bu kısımda Firebase'den veriler çekilir)
                books = demoBooks
            }
        }
    }
    
    // MARK: - UI Bileşenleri
    
    private var filterBar: some View {
        VStack(spacing: 0) {
            // Filtre butonları
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    FilterButton(title: "Tümü", isSelected: selectedFilter == .all) {
                        selectedFilter = .all
                    }
                    
                    FilterButton(title: "Okuyorum", isSelected: selectedFilter == .currentlyReading) {
                        selectedFilter = .currentlyReading
                    }
                    
                    FilterButton(title: "Tamamlanan", isSelected: selectedFilter == .completed) {
                        selectedFilter = .completed
                    }
                    
                    FilterButton(title: "Favoriler", isSelected: selectedFilter == .favorites) {
                        selectedFilter = .favorites
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            
            // Sıralama menüsü
            HStack {
                Text("Sırala:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("Sırala", selection: $selectedSortOrder) {
                    Text("Başlık").tag(BookSortOrder.title)
                    Text("Yazar").tag(BookSortOrder.author)
                    Text("Eklenme Tarihi").tag(BookSortOrder.dateAdded)
                    Text("Bitiş Tarihi").tag(BookSortOrder.dateFinished)
                    Text("İlerleme").tag(BookSortOrder.readingProgress)
                }
                .pickerStyle(MenuPickerStyle())
                
                Spacer()
                
                // 3D görünüm butonu
                Button(action: {
                    // 3D kitaplık görünümünü aç
                    showBookshelfView = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "cube")
                        Text("3D")
                            .font(.caption)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
                
                Text("\(filteredBooks.count) kitap")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            Divider()
        }
        .background(Color(.systemBackground))
    }
    
    private var bookList: some View {
        ZStack {
            if filteredBooks.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text(searchText.isEmpty ? "Kitaplığınız boş" : "Sonuç bulunamadı")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if searchText.isEmpty {
                        Button(action: {
                            showAddBookSheet = true
                        }) {
                            Text("Kitap Ekle")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                }
            } else {
                List {
                    ForEach(filteredBooks) { book in
                        NavigationLink(destination: BookDetailView(book: book)) {
                            BookRowView(book: book)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
}

// MARK: - Yardımcı Yapılar ve Görünümler

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .medium : .regular)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                .foregroundColor(isSelected ? .blue : .primary)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct BookRowView: View {
    let book: Book
    
    var body: some View {
        HStack(spacing: 15) {
            // Kitap kapağı
            ZStack {
                if let coverURL = book.coverURL {
                    AsyncImage(url: coverURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 60, height: 80)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 80)
                        .overlay(
                            Text(book.title.prefix(1))
                                .font(.headline)
                                .foregroundColor(.gray)
                        )
                }
            }
            .cornerRadius(6)
            .shadow(radius: 1)
            
            // Kitap bilgileri
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Alt bilgiler
                HStack(spacing: 8) {
                    // Durum göstergesi
                    HStack(spacing: 4) {
                        Circle()
                            .fill(book.isCompleted ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        
                        Text(book.isCompleted ? "Tamamlandı" : "Okunuyor")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if book.isCompleted, let rating = book.rating {
                        // Derecelendirme
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            
                            Text("\(rating)/5")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        // İlerleme
                        Text("\(Int(book.readingProgress))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Favoriler işareti
            if book.isFavorite {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 16))
            }
        }
        .padding(.vertical, 4)
    }
}

// Kitaplar için filtre seçenekleri
enum BookFilter {
    case all
    case currentlyReading
    case completed
    case favorites
}

// Demo: Kitap ekleme formu
struct AddBookView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchQuery = ""
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Bu sayfada kitap arama ve ekleme formu olacak")
                    .padding()
            }
            .navigationTitle("Kitap Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MyLibraryView_Previews: PreviewProvider {
    static var previews: some View {
        MyLibraryView()
            .environmentObject(AuthViewModel())
    }
} 