import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var bookViewModel: BookViewModel
    @State private var is3DView = false
    @State private var showingAddBookOptions = false
    @State private var selectedCategory: BookCategory = .all
    @State private var searchText = ""
    
    enum BookCategory: String, CaseIterable {
        case all = "Tümü"
        case currentlyReading = "Okunan"
        case completed = "Tamamlanan"
        case wishlist = "İstek Listesi"
    }
    
    var filteredBooks: [GoogleBook] {
        let books: [GoogleBook]
        
        switch selectedCategory {
        case .all:
            books = bookViewModel.allBooks
        case .currentlyReading:
            books = bookViewModel.currentlyReadingBooks
        case .completed:
            books = bookViewModel.completedBooks
        case .wishlist:
            books = bookViewModel.wishlistBooks
        }
        
        if searchText.isEmpty {
            return books
        } else {
            return books.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                book.authors.joined(separator: " ").localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Arama çubuğu
                    searchBar
                    
                    // Kategori filtreleri
                    categoryPicker
                        .padding(.top, 10)
                    
                    // Kitaplar
                    ScrollView {
                        // Üst bilgi kartı
                        libraryStatsCard
                            .padding(.top, 20)
                            .padding(.horizontal)
                        
                        // Kitap grid görünümü
                        LazyVGrid(
                            columns: [
                                GridItem(.adaptive(minimum: 160, maximum: 160), spacing: 20)
                            ],
                            spacing: 20
                        ) {
                            ForEach(filteredBooks) { book in
                                NavigationLink(destination: BookDetailView(book: book)) {
                                    BookCard(book: book)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                        .animation(.easeInOut, value: filteredBooks.count)
                        
                        if filteredBooks.isEmpty {
                            emptyStateView
                                .padding(.top, 50)
                        }
                    }
                }
            }
            .navigationTitle("Kütüphanem")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        bookViewModel.synchronizeBooks()
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        is3DView.toggle()
                    }) {
                        Image(systemName: "books.vertical.fill")
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddBookOptions = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $is3DView) {
                Library3DView()
            }
            .actionSheet(isPresented: $showingAddBookOptions) {
                ActionSheet(
                    title: Text("Kitap Ekle"),
                    message: Text("Kitap eklemek için bir yöntem seçin"),
                    buttons: [
                        .default(Text("ISBN ile Tara")) {
                            // ISBN tarama ekranı
                        },
                        .default(Text("İsimle Ara")) {
                            // Kitap arama ekranı
                        },
                        .default(Text("Manuel Ekle")) {
                            // Manuel kitap ekleme
                        },
                        .cancel(Text("İptal"))
                    ]
                )
            }
            .onAppear {
                // Kütüphane verilerini senkronize et
                bookViewModel.synchronizeBooks()
            }
        }
    }
    
    // Arama çubuğu
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Kitap veya yazar ara", text: $searchText)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top, 10)
    }
    
    // Kategori seçici
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(BookCategory.allCases, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        Text(category.rawValue)
                            .fontWeight(selectedCategory == category ? .bold : .regular)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedCategory == category ? Color.blue : Color(UIColor.tertiarySystemBackground))
                            )
                            .foregroundColor(selectedCategory == category ? .white : .primary)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // Kütüphane istatistikleri kartı
    private var libraryStatsCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 25) {
                statItem(count: bookViewModel.allBooks.count, label: "Toplam", icon: "books.vertical.fill", color: .blue)
                
                Divider()
                    .frame(height: 40)
                
                statItem(count: bookViewModel.completedBooks.count, label: "Okunan", icon: "checkmark.circle.fill", color: .green)
                
                Divider()
                    .frame(height: 40)
                
                statItem(count: bookViewModel.currentlyReadingBooks.count, label: "Devam Eden", icon: "book.fill", color: .orange)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 15)
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
    }
    
    // İstatistik öğesi
    private func statItem(count: Int, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // Boş durum görünümü
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 70))
                .foregroundColor(.blue.opacity(0.7))
            
            Text("Hiç kitap bulunamadı")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Kütüphanenize kitap eklemek için sağ üstteki + düğmesine tıklayın")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

// Kitap Kartı
struct BookCard: View {
    let book: GoogleBook
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Kitap kapağı
            ZStack {
                if let url = book.thumbnailURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 160, height: 220)
                                .clipped()
                        case .empty:
                            ProgressView()
                                .frame(width: 160, height: 220)
                        case .failure:
                            defaultCover
                                .frame(width: 160, height: 220)
                        @unknown default:
                            defaultCover
                                .frame(width: 160, height: 220)
                        }
                    }
                } else {
                    defaultCover
                        .frame(width: 160, height: 220)
                }
            }
            .frame(width: 160, height: 220)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
            .overlay(
                statusBadge
                    .padding(8),
                alignment: .topTrailing
            )
                
            // Kitap bilgileri
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(2)
                    .frame(width: 160, alignment: .leading)
                    .foregroundColor(.primary)
                
                Text(book.authors.joined(separator: ", "))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .frame(width: 160, alignment: .leading)
                
                HStack {
                    if book.readingProgressPercentage > 0 {
                        ProgressView(value: book.readingProgressPercentage, total: 100)
                            .progressViewStyle(LinearProgressViewStyle(tint: progressColor(for: book.readingStatus)))
                            .frame(height: 5)
                        
                        Text("\(Int(book.readingProgressPercentage))%")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 160, alignment: .leading)
                .padding(.top, 4)
            }
            .padding(.horizontal, 4)
        }
        .frame(width: 160)
        .padding(.bottom, 10)
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var defaultCover: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 5) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.9))
                
                Text(book.title)
                    .font(.system(size: 16, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal, 15)
                    .lineLimit(3)
                
                if !book.authors.isEmpty {
                    Text(book.authors.first ?? "")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
            }
            .padding()
        }
    }
    
    private var statusBadge: some View {
        HStack {
            switch book.readingStatus {
            case .inProgress:
                Image(systemName: "book.fill")
                    .foregroundColor(.white)
                Text("Okunuyor")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
            case .finished:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white)
                Text("Tamamlandı")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
            case .notStarted:
                EmptyView()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(statusColor(for: book.readingStatus))
                .opacity(book.readingStatus == .notStarted ? 0 : 0.9)
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
    
    private func progressColor(for status: ReadingStatus) -> Color {
        switch status {
        case .notStarted:
            return .gray.opacity(0.5)
        case .inProgress:
            return .blue
        case .finished:
            return .green
        }
    }
}

// 3D Kitaplık Görünümü
struct Library3DView: View {
    @EnvironmentObject var bookViewModel: BookViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                // Arka plan - kitaplık duvarı görünümü
                Color(#colorLiteral(red: 0.9254902005, green: 0.8941176534, blue: 0.8196078539, alpha: 1)) // Açık ahşap rengi
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Başlık ve açıklama
                    VStack(spacing: 8) {
                        Text("3D Kitaplık")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundColor(Color(#colorLiteral(red: 0.3176470697, green: 0.07450980693, blue: 0.02745098062, alpha: 1)))
                        
                        Text("Kitaplarınız sanal kitaplığınızda")
                            .font(.subheadline)
                            .foregroundColor(Color(#colorLiteral(red: 0.3176470697, green: 0.07450980693, blue: 0.02745098062, alpha: 1)).opacity(0.7))
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                    
                    // Kayan kitap rafları
                    ScrollView {
                        VStack(spacing: 50) {
                            // Her raf
                            ForEach(0..<bookshelves.count, id: \.self) { shelfIndex in
                                LibraryShelfView(
                                    books: bookshelves[shelfIndex],
                                    shelfColor: shelfColors[shelfIndex % shelfColors.count]
                                )
                            }
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarItems(trailing: Button("Kapat") {
                presentationMode.wrappedValue.dismiss()
            })
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // Renk tonları
    private let shelfColors: [Color] = [
        Color(#colorLiteral(red: 0.5058823824, green: 0.3372549117, blue: 0.06666667014, alpha: 1)), // Koyu ahşap
        Color(#colorLiteral(red: 0.5787474513, green: 0.3215198815, blue: 0, alpha: 1)), // Orta ahşap
        Color(#colorLiteral(red: 0.6679978967, green: 0.4751212597, blue: 0.2586010993, alpha: 1)) // Açık ahşap
    ]
    
    // Kitap rafları oluştur (her raf maksimum 6 kitap içerir)
    private var bookshelves: [[GoogleBook]] {
        let books = bookViewModel.allBooks
        var shelves: [[GoogleBook]] = []
        let booksPerShelf = 6
        
        var currentShelf: [GoogleBook] = []
        for book in books {
            currentShelf.append(book)
            
            if currentShelf.count >= booksPerShelf {
                shelves.append(currentShelf)
                currentShelf = []
            }
        }
        
        if !currentShelf.isEmpty {
            shelves.append(currentShelf)
        }
        
        return shelves
    }
}

// Kitap rafı görünümü
struct LibraryShelfView: View {
    let books: [GoogleBook]
    let shelfColor: Color
    
    var body: some View {
        VStack(spacing: 0) {
            // Kitaplar
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(books) { book in
                    Book3DView(book: book)
                        .frame(maxWidth: .infinity)
                }
                
                // Boş kitap yerleri
                if books.count < 6 {
                    ForEach(0..<(6 - books.count), id: \.self) { _ in
                        Spacer()
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 5)
            
            // Raf
            ZStack {
                // Raf gövdesi
                Rectangle()
                    .fill(shelfColor)
                    .frame(height: 15)
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 2)
                
                // Raf ön kenarı (derinlik efekti için)
                Rectangle()
                    .fill(shelfColor.opacity(0.7))
                    .frame(height: 4)
                    .offset(y: 8)
            }
            
            // Raf destek ayakları
            HStack {
                Spacer()
                
                Rectangle()
                    .fill(shelfColor)
                    .frame(width: 8, height: 20)
                
                Spacer()
                Spacer()
                
                Rectangle()
                    .fill(shelfColor)
                    .frame(width: 8, height: 20)
                
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

// 3D Kitap Görünümü
struct Book3DView: View {
    let book: GoogleBook
    @State private var isHovered = false
    
    var body: some View {
        ZStack {
                        // Kitap kapağı
            VStack(spacing: 0) {
                        if let url = book.thumbnailURL {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                .frame(width: 70, height: 110)
                                .clipped()
                                .cornerRadius(2)
                                .shadow(color: Color.black.opacity(0.4), radius: 2, x: 2, y: 2)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                                )
                                .rotation3DEffect(
                                    .degrees(isHovered ? 15 : 5),
                                    axis: (x: 0, y: 1, z: 0)
                                )
                        case .empty:
                            ProgressView()
                                .frame(width: 70, height: 110)
                                case .failure:
                            defaultBookCover(title: book.title)
                                @unknown default:
                            defaultBookCover(title: book.title)
                                }
                            }
                        } else {
                    defaultBookCover(title: book.title)
                }
                
                // Kitap alt kenarı (sayfa kenarı görünümü)
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 70, height: 3)
                    .offset(x: isHovered ? 2 : 1, y: -1)
                    .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            #if os(macOS)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.3)) {
                    isHovered = hovering
                }
            }
            #endif
            .onTapGesture {
                withAnimation(.spring()) {
                    isHovered.toggle()
                }
                
                // 2 saniye sonra orijinal konuma dön
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isHovered = false
                    }
                }
            }
        }
        .frame(height: 130)
    }
    
    // Varsayılan kitap kapağı
    private func defaultBookCover(title: String) -> some View {
        ZStack {
            // Kitap kapağı arkaplanı
            Rectangle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        bookColor(for: title),
                        bookColor(for: title).opacity(0.7)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 70, height: 110)
                .cornerRadius(2)
                .shadow(color: Color.black.opacity(0.4), radius: 2, x: 2, y: 2)
                .overlay(
                    Rectangle()
                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                )
                .rotation3DEffect(
                    .degrees(isHovered ? 15 : 5),
                    axis: (x: 0, y: 1, z: 0)
                )
            
            // Kitap bilgileri
                VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 10, weight: .medium, design: .serif))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 4)
                
                if let author = book.authors.first {
                    Text(author)
                        .font(.system(size: 8, weight: .light, design: .serif))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                        .padding(.horizontal, 4)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // Kitaba özgü renk oluştur
    private func bookColor(for title: String) -> Color {
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
}

#Preview {
    LibraryView()
        .environmentObject(BookViewModel())
} 