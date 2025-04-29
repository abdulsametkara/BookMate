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
                NavigationLink(destination: BookDetailView(book: currentBook)) {
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
    private func currentlyReadingCard(_ book: GoogleBook) -> some View {
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
                        NavigationLink(destination: BookDetailView(book: book)) {
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
    private func recentBookCard(_ book: GoogleBook) -> some View {
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
                    Text(book.readingStatus.displayName)
                        .font(.caption)
                        .foregroundColor(book.readingStatus == .inProgress ? secondaryColor : .secondary)
                    
                    Spacer()
                }
            }
        }
        .padding(12)
        .frame(width: 270, height: 120, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // İstatistikler bölümü
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("İstatistikler")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal, 20)
            
            HStack(spacing: 16) {
                // Tamamlanan kitaplar
                statsCard(
                    count: bookViewModel.completedBooks.count,
                    title: "Bitirilen Kitap",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                // Toplam kitaplar
                statsCard(
                    count: bookViewModel.userLibrary.count,
                    title: "Toplam Kitap",
                    icon: "books.vertical.fill",
                    color: primaryColor
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    // İstatistik kartı
    private func statsCard(count: Int, title: String, icon: String, color: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(count)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // Boş okuma durumu
    private var emptyReadingState: some View {
        VStack(spacing: 12) {
            Image(systemName: "book")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            Text("Şu an okuduğunuz bir kitap yok")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text("Bir kitabı okumaya başlamak için kütüphanenize gidin ve 'Şu An Okuyorum' olarak işaretleyin")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            NavigationLink(destination: BookListView()) {
                Text("Kütüphaneye Git")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(primaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .padding(.top, 8)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal, 20)
    }
    
    // Kitap kapağı görünümü
    private func bookCoverView(for book: GoogleBook) -> some View {
        Group {
            if let thumbnailURL = book.thumbnailURL {
                AsyncImage(url: thumbnailURL) { phase in
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
            } else {
                bookCoverPlaceholder
            }
        }
    }
    
    // Kitap kapağı placeholder
    private var bookCoverPlaceholder: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .overlay(
                Image(systemName: "book.closed")
                    .font(.system(size: 30))
                    .foregroundColor(.gray)
            )
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

#Preview {
    let bookVM = BookViewModel()
    let userVM = BookMate.UserViewModel()
    return HomeView()
        .environmentObject(bookVM)
        .environmentObject(userVM)
} 