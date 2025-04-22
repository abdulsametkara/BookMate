import SwiftUI

struct BookshelfView: View {
    @EnvironmentObject var bookViewModel: BookViewModel
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedBook: GoogleBook? = nil
    @State private var showDetail = false
    
    var body: some View {
        ZStack {
            // Arkaplan
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Başlık Alanı
                VStack(spacing: 6) {
                    Text("Kütüphanem")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .padding(.top)
                    
                    Text("Kitaplığınızda \(bookViewModel.userLibrary.count) kitap var")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 10)
                
                // Kitaplık
                ScrollView(.vertical, showsIndicators: false) {
                    if bookViewModel.userLibrary.isEmpty {
                        emptyLibraryView
                    } else {
                        bookshelvesView
                    }
                }
                .padding(.horizontal)
            }
            
            // Kitap detay görünümü
            if showDetail, let book = selectedBook {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring()) {
                            showDetail = false
                        }
                    }
                
                BookshelfItemDetailView(book: book, isShowing: $showDetail)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showDetail)
    }
    
    // Boş kitaplık görünümü
    private var emptyLibraryView: some View {
        VStack(spacing: 25) {
            Image(systemName: "books.vertical.circle")
                .font(.system(size: 80))
                .foregroundColor(.orange)
                .opacity(0.8)
            
            Text("Kitaplığınız Boş")
                .font(.title)
                .fontWeight(.medium)
            
            Text("Okuma serüveninize başlamak için kitap ekleyin.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Örnek gösterim
            sampleBookDisplay
                .padding(.top, 20)
        }
        .padding(.vertical, 60)
    }
    
    // Örnek kitap gösterimi
    private var sampleBookDisplay: some View {
        VStack(spacing: 15) {
            Text("Nasıl Görünecek?")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ZStack {
                // Raf arkaplanı
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.brown.opacity(0.2))
                    .frame(height: 160)
                
                // Kitaplar
                HStack(spacing: 15) {
                    ForEach(0..<3) { i in
                        ModernBookView(
                            title: ["Kitaplığa Ekle", "Yeni Kitap", "Okumaya Başla"][i],
                            color: [.red, .blue, .purple][i],
                            height: [140, 130, 135][i]
                        )
                    }
                }
                
                // Raf kenarı
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.brown)
                        .frame(height: 12)
                        .shadow(color: .black.opacity(0.2), radius: 2, y: 2)
                }
            }
            .frame(width: 260)
        }
    }
    
    // Kitaplık rafları
    private var bookshelvesView: some View {
        VStack(spacing: 40) {
            ForEach(0..<min(5, (bookViewModel.userLibrary.count + 4) / 5)) { shelfIndex in
                modernBookshelfView(shelfIndex: shelfIndex)
            }
        }
        .padding(.vertical, 10)
    }
    
    // Modern kitaplık rafı
    private func modernBookshelfView(shelfIndex: Int) -> some View {
        let startIndex = shelfIndex * 5 // Her rafta 5 kitap
        
        // Bu raf için kitaplar
        let shelfBooks: [GoogleBook] = {
            guard startIndex < bookViewModel.userLibrary.count else { return [] }
            
            var books: [GoogleBook] = []
            
            // startIndex'ten başlayarak en fazla 5 kitap al (veya mevcut kitap sayısı kadar)
            for i in 0..<5 { // Sabit sayı kullanarak hatayı giderelim
                if startIndex + i < bookViewModel.userLibrary.count {
                    books.append(bookViewModel.userLibrary[startIndex + i])
                } else {
                    break // Yeterli kitap yoksa döngüden çık
                }
            }
            return books
        }()
        
        return ZStack {
            // Raf arkaplanı - 3D görünüm için gradyan
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(UIColor(red: 0.95, green: 0.9, blue: 0.8, alpha: 1.0)),
                            Color(UIColor(red: 0.85, green: 0.75, blue: 0.65, alpha: 1.0))
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 180)
                .shadow(color: .black.opacity(0.1), radius: 5, y: 3)
            
            // Kitaplar
            HStack(alignment: .bottom, spacing: 15) {
                ForEach(0..<shelfBooks.count, id: \.self) { index in
                    let book = shelfBooks[index]
                    ModernBookView(
                        title: book.title,
                        color: Color(getBookColor(for: book, variation: index)),
                        height: 150
                    )
                    .onTapGesture {
                        selectedBook = book
                        withAnimation(.spring()) {
                            showDetail = true
                        }
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 14)
            
            // Raf kenarı - 3D görünüm
            VStack {
                Spacer()
                ZStack {
                    // Alt gölge - derinlik için
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.brown.opacity(0.7))
                        .frame(height: 14)
                        .offset(y: 2)
                        .blur(radius: 2)
                    
                    // Raf kenarı
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)),
                                    Color(UIColor(red: 0.4, green: 0.25, blue: 0.1, alpha: 1.0))
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 14)
                }
            }
        }
    }
    
    // Kitap rengi belirleme - variation parametresiyle aynı türdeki kitapların renkleri farklılaştırılıyor
    private func getBookColor(for book: GoogleBook, variation: Int) -> UIColor {
        // Kitap türüne veya ID'sine göre tutarlı bir renk üret
        let colors: [UIColor] = [
            UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0), // Kırmızı
            UIColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 1.0), // Mavi
            UIColor(red: 0.3, green: 0.7, blue: 0.3, alpha: 1.0), // Yeşil
            UIColor(red: 0.8, green: 0.6, blue: 0.2, alpha: 1.0), // Sarı
            UIColor(red: 0.5, green: 0.3, blue: 0.8, alpha: 1.0), // Mor
            UIColor(red: 0.8, green: 0.3, blue: 0.6, alpha: 1.0), // Pembe
            UIColor(red: 0.3, green: 0.7, blue: 0.8, alpha: 1.0), // Turkuaz
            UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)  // Kahverengi
        ]
        
        // Tutarlı bir renk seçimi için kitap başlığını kullan (ID yerine)
        var hash = abs(book.title.hashValue)
        // Varyasyona göre hafif renk değişimi
        hash = (hash + variation * 7) % colors.count
        
        return colors[hash]
    }
}

// Modern Kitap Görünümü
struct ModernBookView: View {
    let title: String
    let color: Color
    let height: CGFloat
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Kitap gövdesi
            ZStack(alignment: .bottom) {
                // Kitap ana gövdesi
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: 40, height: height)
                
                // Kitap sayfaları (yan)
                Rectangle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 4, height: height - 5)
                    .offset(x: 18)
                
                // Kitabın üstü (kapak)
                Rectangle()
                    .fill(color.opacity(0.8))
                    .frame(width: 40, height: 6)
                    .offset(y: -height / 2 + 3)
            }
            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 2, y: 2)
            
            // Kitap başlığı (dikdörtgen etiketi)
            VStack {
                Spacer()
                    .frame(height: height * 0.28)
                
                // Başlık etiketi
                ZStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 34, height: 46)
                    
                    Text(title.count > 10 ? title.prefix(10) + "..." : title)
                        .font(.system(size: 8, weight: .medium))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black)
                        .frame(width: 30)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(4)
                }
                .rotationEffect(.degrees(-90))
                .offset(x: -3, y: 0)
                
                Spacer()
            }
        }
    }
}

// Kitap Detay Görünümü
struct BookshelfItemDetailView: View {
    let book: GoogleBook
    @Binding var isShowing: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Üst çizgi - kullanıcı aşağı sürükleyebilir
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray.opacity(0.5))
                .frame(width: 40, height: 4)
                .padding(.top, 6)
                .padding(.bottom, 10)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Başlık ve yazar
                    VStack(alignment: .leading, spacing: 8) {
                        Text(book.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if !book.authors.joined(separator: ", ").isEmpty {
                            Text(book.authors.joined(separator: ", "))
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Kitap ve ilerleme
                    HStack(spacing: 20) {
                        // Kitap görseli
                        ZStack {
                            if let url = book.thumbnailURL {
                                AsyncImage(url: url) { phase in
                                    if let image = phase.image {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 100, height: 150)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .shadow(radius: 5)
                                    } else {
                                        bookCover
                                    }
                                }
                            } else {
                                bookCover
                            }
                        }
                        
                        // Bilgiler
                        VStack(alignment: .leading, spacing: 12) {
                            // Sayfa ilerlemesi
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Okuma İlerlemesi")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    let progress = calculateBookProgress(book)
                                    
                                    ProgressView(value: progress.progress)
                                        .progressViewStyle(LinearProgressViewStyle(tint: Color.blue))
                                        .frame(height: 8)
                                    
                                    Text("\(progress.percentage)%")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            // Sayfa bilgisi
                            if let pageCount = book.pageCount {
                                HStack {
                                    Label("\(book.currentPage ?? 0) / \(pageCount) sayfa", systemImage: "book")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // Tür bilgisi
                            if let categories = book.categories, !categories.isEmpty {
                                HStack {
                                    Text(categories.prefix(2).joined(separator: ", "))
                                        .font(.subheadline)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.blue.opacity(0.15))
                                        .foregroundColor(.blue)
                                        .clipShape(Capsule())
                                }
                            }
                            
                            // Yayın bilgisi
                            if let publisher = book.publisher {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Yayınevi:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(publisher)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                    )
                    
                    // Özet
                    if let description = book.description, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Özet")
                                .font(.headline)
                            
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(6)
                        }
                        .padding(.vertical, 10)
                    }
                    
                    // Okuma durumu
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Okuma Durumu")
                            .font(.headline)
                        
                        HStack(spacing: 20) {
                            statusCard(title: "Başlanmadı", 
                                       isActive: book.readingStatus == .notStarted, 
                                       icon: "book.closed")
                            
                            statusCard(title: "Okunuyor", 
                                       isActive: book.readingStatus == .inProgress, 
                                       icon: "book")
                            
                            statusCard(title: "Tamamlandı", 
                                       isActive: book.readingStatus == .finished, 
                                       icon: "book.fill")
                        }
                    }
                    .padding(.vertical, 10)
                    
                    // Butonlar
                    HStack(spacing: 10) {
                        Button(action: {
                            // Okumaya devam et
                        }) {
                            Label("Okumaya Devam Et", systemImage: "book.fill")
                                .font(.headline)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button(action: {
                            withAnimation(.spring()) {
                                isShowing = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.headline)
                                .padding(.vertical, 12)
                                .frame(width: 50)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 10)
                }
                .padding()
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colorScheme == .dark ? Color(.systemBackground) : Color.white)
                .shadow(color: Color.black.opacity(0.2), radius: 15, x: 0, y: 5)
        )
        .frame(maxHeight: 550)
        .padding(.horizontal)
    }
    
    // Kitap kapağı
    private var bookCover: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(getBookColor(for: book)))
            .frame(width: 100, height: 150)
            .shadow(radius: 5)
            .overlay(
                VStack {
                    Spacer()
                        .frame(height: 30)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white)
                        .frame(width: 80, height: 50)
                        .overlay(
                            Text(book.title)
                                .font(.system(size: 10, weight: .medium))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.black)
                                .lineLimit(3)
                                .padding(5)
                        )
                    
                    Spacer()
                }
            )
    }
    
    // Durum kartı
    private func statusCard(title: String, isActive: Bool, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(isActive ? .blue : .gray)
            
            Text(title)
                .font(.caption)
                .foregroundColor(isActive ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1))
        )
    }
    
    // Kitap rengi belirleme
    private func getBookColor(for book: GoogleBook) -> UIColor {
        // Kitap türüne veya ID'sine göre tutarlı bir renk üret
        let colors: [UIColor] = [
            UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0), // Kırmızı
            UIColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 1.0), // Mavi
            UIColor(red: 0.3, green: 0.7, blue: 0.3, alpha: 1.0), // Yeşil
            UIColor(red: 0.8, green: 0.6, blue: 0.2, alpha: 1.0), // Sarı
            UIColor(red: 0.5, green: 0.3, blue: 0.8, alpha: 1.0), // Mor
            UIColor(red: 0.8, green: 0.3, blue: 0.6, alpha: 1.0), // Pembe
            UIColor(red: 0.3, green: 0.7, blue: 0.8, alpha: 1.0), // Turkuaz
            UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)  // Kahverengi
        ]
        
        // Tutarlı bir renk seçimi için kitap başlığını kullan (ID yerine)
        let hash = abs(book.title.hashValue)
        let index = hash % colors.count
        return colors[index]
    }
    
    // İlerleme hesaplama
    private func calculateBookProgress(_ book: GoogleBook) -> (progress: Double, percentage: Int) {
        let currentPage = book.currentPage ?? 0
        let pageCount = book.pageCount ?? 1
        
        let progress = Double(currentPage) / Double(max(1, pageCount))
        let percentage = Int(progress * 100)
        
        return (progress, percentage)
    }
}

struct BookshelfView_Previews: PreviewProvider {
    static var previews: some View {
        BookshelfView()
            .environmentObject(BookViewModel())
    }
} 