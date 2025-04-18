import SwiftUI

struct BookListView: View {
    @State private var books: [Book] = []
    @State private var searchText = ""
    @State private var isSearchActive = false
    @State private var showingAddBookSheet = false
    @State private var selectedFilterOption: FilterOption = .all
    var viewTitle: String = "Kitaplığım"
    var bookViewModel: BookViewModel?
    
    // Varsayılan yapılandırıcı (mevcut)
    init() {
        self.viewTitle = "Kitaplığım"
    }
    
    // HomeView'dan çağrıldığında kullanılan yapılandırıcı
    init(books: [Book], title: String, bookViewModel: BookViewModel) {
        self._books = State(initialValue: books)
        self.viewTitle = title
        self.bookViewModel = bookViewModel
    }
    
    enum FilterOption: String, CaseIterable, Identifiable {
        case all = "Tümü"
        case notStarted = "Başlanmadı"
        case inProgress = "Okunuyor"
        case finished = "Tamamlandı"
        
        var id: String { rawValue }
        
        var readingStatus: ReadingStatus? {
            switch self {
            case .all: return nil
            case .notStarted: return .notStarted
            case .inProgress: return .inProgress
            case .finished: return .finished
            }
        }
    }
    
    private var filteredBooks: [Book] {
        var result = books
        
        // Okuma durumu filtreleme
        if let status = selectedFilterOption.readingStatus {
            result = result.filter { $0.readingStatus == status }
        }
        
        // Arama metni filtreleme
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.authorsText.localizedCaseInsensitiveContains(searchText) ||
                ($0.publisher?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return result
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filtre menüsü
                filterMenu
                
                // Kitap listesi
                List {
                    ForEach(filteredBooks) { book in
                        NavigationLink {
                            BookDetailView(book: book)
                        } label: {
                            BookRow(book: book)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                if let index = books.firstIndex(where: { $0.id == book.id }) {
                                    books.remove(at: index)
                                }
                            } label: {
                                Label("Sil", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .overlay {
                    if filteredBooks.isEmpty {
                        emptyStateView
                    }
                }
            }
            .navigationTitle(viewTitle)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Kitap, yazar veya yayınevi ara")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddBookSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddBookSheet) {
                AddBookView { newBook in
                    books.append(newBook)
                }
            }
            .onAppear {
                // Test kitapları (gerçek uygulamada veri depolama servisi kullanılacak)
                if books.isEmpty && bookViewModel == nil {
                    books = BookListView.testBooks
                }
            }
        }
    }
    
    private var filterMenu: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(FilterOption.allCases) { option in
                    FilterChip(
                        title: option.rawValue,
                        isSelected: option == selectedFilterOption
                    ) {
                        selectedFilterOption = option
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            if !searchText.isEmpty {
                Text("Arama sonucu bulunamadı")
                    .font(.headline)
                    .foregroundColor(.secondary)
            } else if selectedFilterOption != .all {
                Text("\(selectedFilterOption.rawValue) durumunda kitap yok")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Button("Tüm Kitapları Göster") {
                    selectedFilterOption = .all
                }
                .buttonStyle(.bordered)
            } else {
                Text("Kitaplığınız boş")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Button {
                    showingAddBookSheet = true
                } label: {
                    Text("Kitap Ekle")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// Kitap satır görünümü
struct BookRow: View {
    let book: Book
    
    var body: some View {
        HStack(spacing: 15) {
            // Kitap kapağı
            if let url = book.thumbnailURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 75)
                            .cornerRadius(6)
                    } else {
                        bookPlaceholder
                    }
                }
                .frame(width: 50, height: 75)
            } else {
                bookPlaceholder
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
                
                Spacer(minLength: 5)
                
                // Alt bilgiler
                HStack {
                    Text(book.readingStatus.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor(for: book.readingStatus).opacity(0.1))
                        .foregroundColor(statusColor(for: book.readingStatus))
                        .cornerRadius(12)
                    
                    Spacer()
                    
                    // İlerleme (eğer okunuyorsa)
                    if book.readingStatus == .inProgress {
                        Text("\(Int(book.readingProgressPercentage))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 5)
    }
    
    private var bookPlaceholder: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .frame(width: 50, height: 75)
            .cornerRadius(6)
            .overlay(
                Image(systemName: "book.closed")
                    .foregroundColor(.gray)
            )
    }
    
    private func statusColor(for status: ReadingStatus) -> Color {
        switch status {
        case .notStarted:
            return .gray
        case .inProgress:
            return .blue
        case .finished:
            return .green
        }
    }
}

// Filtre Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

// Test verileri
extension BookListView {
    static var testBooks: [Book] = [
        Book(
            id: UUID(),
            isbn: "9780307474278",
            title: "Dune",
            authors: ["Frank Herbert"],
            description: "Set on the desert planet Arrakis, Dune is the story of the boy Paul Atreides, heir to a noble family tasked with ruling an inhospitable world where the only thing of value is the \"spice\" melange, a drug capable of extending life and enhancing consciousness. Coveted across the known universe, melange is a prize worth killing for...",
            pageCount: 528,
            categories: ["Fiction", "Science Fiction"],
            imageLinks: ImageLinks(
                small: "https://books.google.com/books/content?id=B1hSG45JCX4C&printsec=frontcover&img=1&zoom=2&edge=curl&source=gbs_api",
                thumbnail: "https://books.google.com/books/content?id=B1hSG45JCX4C&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api",
                medium: "https://books.google.com/books/content?id=B1hSG45JCX4C&printsec=frontcover&img=1&zoom=3&edge=curl&source=gbs_api",
                large: "https://books.google.com/books/content?id=B1hSG45JCX4C&printsec=frontcover&img=1&zoom=4&edge=curl&source=gbs_api"
            ),
            publishedDate: "1990-09-01",
            publisher: "Penguin",
            language: "en",
            readingStatus: .inProgress,
            readingProgressPercentage: 35,
            userNotes: "Çok etkileyici bir bilim kurgu kitabı. Siyasi entrikalar ve karakter gelişimleri çok iyi işlenmiş."
        ),
        Book(
            id: UUID(),
            isbn: "9780553593716",
            title: "A Game of Thrones",
            authors: ["George R.R. Martin"],
            description: "Winter is coming. Such is the stern motto of House Stark, the northernmost of the fiefdoms that owe allegiance to King Robert Baratheon in far-off King's Landing. There Eddard Stark of Winterfell rules in Robert's name. There his family dwells in peace and comfort: his proud wife, Catelyn; his sons Robb, Brandon, and Rickon; his daughters Sansa and Arya; and his bastard son, Jon Snow.",
            pageCount: 694,
            categories: ["Fiction", "Fantasy"],
            imageLinks: ImageLinks(
                small: "https://books.google.com/books/content?id=5NomkK4EV68C&printsec=frontcover&img=1&zoom=2&edge=curl&source=gbs_api",
                thumbnail: "https://books.google.com/books/content?id=5NomkK4EV68C&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api",
                medium: "https://books.google.com/books/content?id=5NomkK4EV68C&printsec=frontcover&img=1&zoom=3&edge=curl&source=gbs_api",
                large: "https://books.google.com/books/content?id=5NomkK4EV68C&printsec=frontcover&img=1&zoom=4&edge=curl&source=gbs_api"
            ),
            publishedDate: "1996-08-01",
            publisher: "Bantam",
            language: "en",
            readingStatus: .notStarted,
            readingProgressPercentage: 0,
            userNotes: nil
        ),
        Book(
            id: UUID(),
            isbn: "9780747532743",
            title: "Harry Potter and the Philosopher's Stone",
            authors: ["J.K. Rowling"],
            description: "Harry Potter has never even heard of Hogwarts when the letters start dropping on the doormat at number four, Privet Drive. Addressed in green ink on yellowish parchment with a purple seal, they are swiftly confiscated by his grisly aunt and uncle. Then, on Harry's eleventh birthday, a great beetle-eyed giant of a man called Rubeus Hagrid bursts in with some astonishing news: Harry Potter is a wizard, and he has a place at Hogwarts School of Witchcraft and Wizardry.",
            pageCount: 223,
            categories: ["Fiction", "Fantasy", "Young Adult"],
            imageLinks: ImageLinks(
                small: "https://books.google.com/books/content?id=39iYWTb6n6cC&printsec=frontcover&img=1&zoom=2&edge=curl&source=gbs_api",
                thumbnail: "https://books.google.com/books/content?id=39iYWTb6n6cC&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api",
                medium: "https://books.google.com/books/content?id=39iYWTb6n6cC&printsec=frontcover&img=1&zoom=3&edge=curl&source=gbs_api",
                large: "https://books.google.com/books/content?id=39iYWTb6n6cC&printsec=frontcover&img=1&zoom=4&edge=curl&source=gbs_api"
            ),
            publishedDate: "1997-06-26",
            publisher: "Bloomsbury",
            language: "en",
            readingStatus: .finished,
            readingProgressPercentage: 100,
            userNotes: "Harika bir fantastik kurgu başlangıcı. Hogwarts dünyası büyüleyici."
        )
    ]
}

// Preview
struct BookListView_Previews: PreviewProvider {
    static var previews: some View {
        BookListView()
    }
}

// Yardımcı bileşenler için yer tutucu
struct AddBookView: View {
    @Environment(\.dismiss) private var dismiss
    let onAddBook: (Book) -> Void
    
    // Gerçek uygulamada, kitap arama ve ekleme için bu görünümü geliştirmek gerekecek
    // Bu sadece yapı için şimdilik yer tutucu
    
    var body: some View {
        NavigationView {
            Text("Bu kısımda Google Books API'den kitap arama ve seçme fonksiyonları eklenecek")
                .padding()
                .navigationTitle("Kitap Ekle")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("İptal") {
                            dismiss()
                        }
                    }
                }
        }
    }
} 