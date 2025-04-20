import SwiftUI

struct HomeView: View {
    @EnvironmentObject var bookViewModel: BookViewModel
    @EnvironmentObject var userViewModel: BookMate.UserViewModel
    
    // Renk sabitleri
    private let primaryColor = Color.blue
    private let secondaryColor = Color.orange
    private let backgroundColor = Color(.systemGroupedBackground)
    
    @State private var showingSearchSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Selamlama ve profil
                    greetingSection
                    
                    // Şu an okunan kitap
                    currentlyReadingSection
                    
                    // Son eklenen kitaplar
                    recentlyAddedSection
                    
                    // İstatistikler
                    statisticsSection
                }
                .padding(.vertical)
            }
            .background(backgroundColor)
            .navigationBarHidden(true)
        }
    }
    
    // Selamlama bölümü
    private var greetingSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                // Selamlama
                Text("Merhaba, \(userViewModel.currentUser?.displayName ?? "Okuyucu")")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Motivasyon mesajı
                Text("Bugün okumak için harika bir gün!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Arama butonu
            Button(action: {
                showingSearchSheet = true
            }) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 22))
                    .foregroundColor(primaryColor)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
            .padding(.trailing, 8)
            
            // Profil resmi ve navigasyon
            NavigationLink(destination: ProfileView()) {
                if let photoURL = userViewModel.currentUser?.profilePhotoURL,
                   let url = URL(string: photoURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 46, height: 46)
                                .clipShape(Circle())
                        default:
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 46, height: 46)
                                .foregroundColor(primaryColor)
                        }
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 46, height: 46)
                        .foregroundColor(primaryColor)
                }
            }
        }
        .padding(.horizontal, 20)
        .sheet(isPresented: $showingSearchSheet) {
            BookSearchView()
                .environmentObject(bookViewModel)
        }
    }
    
    // Şu an okunan kitap bölümü
    private var currentlyReadingSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Şu An Okuyorsunuz")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal, 20)
            
            // Okunan kitap varsa, kitap kartını göster
            if let currentBook = bookViewModel.currentlyReadingBook {
                NavigationLink(destination: NewBookDetailView(book: currentBook)) {
                    currentlyReadingCard(currentBook)
                        .padding(.horizontal, 20)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // Okunan kitap yoksa, boş durum mesajı göster
                emptyReadingState
            }
        }
    }
    
    // Şu an okunan kitap kartı
    private func currentlyReadingCard(_ book: Book) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Kitap kapağı ve ilerleme çubuğu
            ZStack(alignment: .bottom) {
                // Kitap kapağı
                bookCoverView(for: book)
                    .frame(height: 180)
                    .cornerRadius(16, corners: [.topLeft, .topRight])
                
                // İlerleme çubuğu
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sayfa \(Int(book.readingProgressPercentage * Double(book.pageCount ?? 100) / 100)) / \(book.pageCount ?? 100)")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Arka plan
                            Rectangle()
                                .frame(width: geometry.size.width, height: 6)
                                .opacity(0.3)
                                .foregroundColor(.white)
                            
                            // İlerleme
                            Rectangle()
                                .frame(width: geometry.size.width * CGFloat(book.readingProgressPercentage / 100), height: 6)
                                .foregroundColor(.white)
                        }
                        .cornerRadius(3)
                    }
                    .frame(height: 6)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.5))
            }
            
            // Alt kısım - Kitap başlığı ve yazar
            VStack(alignment: .leading, spacing: 8) {
                // Kitap başlığı ve yazar bilgisi
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(book.authorsText)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
                .frame(width: 150, alignment: .leading)
            }
            .padding(12)
            .background(Color.black.opacity(0.7))
            .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
        }
        .frame(width: 160, height: 220)
    }
    
    // Son eklenen kitaplar bölümü
    private var recentlyAddedSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Son Eklenenler")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    // Tümünü göster işlemi
                }) {
                    Text("Tümünü Gör")
                        .font(.subheadline)
                        .foregroundColor(primaryColor)
                }
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(bookViewModel.recentlyAddedBooks) { book in
                        NavigationLink(destination: NewBookDetailView(book: book)) {
                            recentBookCard(book)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }
        }
    }
    
    // Son eklenen kitap kartı
    private func recentBookCard(_ book: Book) -> some View {
        HStack(spacing: 15) {
            // Kitap kapağı
            bookCoverView(for: book)
                .frame(width: 70, height: 100)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // Kitap bilgileri
            VStack(alignment: .leading, spacing: 8) {
                Text(book.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(book.authorsText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    Text(book.readingStatus.description)
                        .font(.caption)
                        .foregroundColor(book.readingStatus == .inProgress ? secondaryColor : .secondary)
                    
                    Spacer()
                }
            }
        }
        .padding(12)
        .frame(width: 270, height: 120, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // Kitap kapağı görünümü
    private func bookCoverView(for book: Book) -> some View {
        Group {
            if let imageUrl = book.thumbnailURL {
                AsyncImage(url: imageUrl) { phase in
                    switch phase {
                    case .empty:
                        bookPlaceholder(for: book)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        bookPlaceholder(for: book)
                    @unknown default:
                        bookPlaceholder(for: book)
                    }
                }
            } else {
                bookPlaceholder(for: book)
            }
        }
    }
    
    // Kapak resmi olmadığında placeholder
    private func bookPlaceholder(for book: Book) -> some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [primaryColor.opacity(0.8), primaryColor]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 8) {
                Image(systemName: "book.closed")
                    .font(.system(size: 30))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(book.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .lineLimit(3)
            }
            .padding(8)
        }
    }
    
    // Henüz kitap okunmadığında gösterilecek durum
    private var emptyReadingState: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 50))
                .foregroundColor(primaryColor.opacity(0.6))
            
            Text("Şu an okumakta olduğunuz kitap yok")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                // Kitap ekleme işlemi
            }) {
                Text("Kitap Ekle")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(primaryColor)
                    .cornerRadius(30)
                    .shadow(color: primaryColor.opacity(0.4), radius: 5, x: 0, y: 3)
            }
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
    }
    
    // İstatistikler bölümü
    private var statisticsSection: some View {
        VStack(spacing: 10) {
            Text("Okuma İstatistikleri")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal, 20)
                .padding(.top, 10)
            
            // İstatistik kartları
            HStack(spacing: 15) {
                // Toplam kitap
                NavigationLink(destination: LibraryView()) {
                    statCard(
                        title: "Toplam Kitap",
                        value: "\(bookViewModel.allBooks.count)",
                        icon: "books.vertical",
                        color: primaryColor
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Tamamlanan kitap
                NavigationLink(destination: CompletedBooksView()) {
                    statCard(
                        title: "Tamamlanan",
                        value: "\(bookViewModel.completedBooks.count)",
                        icon: "checkmark.circle",
                        color: .green
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
    
    // İstatistik kartı
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 15) {
            // İkon
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
        .padding(15)
        .frame(height: 80)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// Özel yuvarlak köşe uzantısı
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// ReadingStatus için açıklama
extension ReadingStatus {
    var description: String {
        switch self {
        case .notStarted:
            return "Henüz Başlanmadı"
        case .inProgress:
            return "Okunuyor"
        case .finished:
            return "Tamamlandı"
        }
    }
}

#Preview {
    let bookVM = BookViewModel()
    let userVM = BookMate.UserViewModel()
    return HomeView()
        .environmentObject(bookVM)
        .environmentObject(userVM)
} 