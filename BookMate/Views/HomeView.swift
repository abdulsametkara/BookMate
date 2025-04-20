import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var searchText = ""
    @State private var currentlyReadingBooks = [Book]()
    @State private var recentlyFinishedBooks = [Book]()
    @State private var partnerActivity: PartnerActivity? = nil
    
    // Demo verisi (gerçek uygulamada burada Firebase'den veri çekilecek)
    let demoCurrentlyReading = [
        Book(id: "1", title: "Dune", author: "Frank Herbert", coverURL: nil, isbn: "9780441172719", pageCount: 412, currentPage: 200, dateAdded: Date(), dateFinished: nil, genre: "Bilim Kurgu", notes: nil, isFavorite: true, rating: nil),
        Book(id: "2", title: "1984", author: "George Orwell", coverURL: nil, isbn: "9780451524935", pageCount: 328, currentPage: 100, dateAdded: Date(), dateFinished: nil, genre: "Distopya", notes: nil, isFavorite: false, rating: nil)
    ]
    
    let demoRecentlyFinished = [
        Book(id: "3", title: "Sapiens", author: "Yuval Noah Harari", coverURL: nil, isbn: "9780062316097", pageCount: 443, currentPage: 443, dateAdded: Date(), dateFinished: Date(), genre: "Tarih", notes: "Mükemmel bir kitap!", isFavorite: true, rating: 5),
        Book(id: "4", title: "Suç ve Ceza", author: "Fyodor Dostoyevski", coverURL: nil, isbn: "9780143107637", pageCount: 671, currentPage: 671, dateAdded: Date(), dateFinished: Date(), genre: "Klasik", notes: nil, isFavorite: true, rating: 4)
    ]
    
    // Demo partner aktivitesi
    let demoPartnerActivity = PartnerActivity(
        partnerName: "Ayşe",
        bookTitle: "Hayvan Çiftliği",
        activityType: .startedReading,
        timestamp: Date().addingTimeInterval(-6000)
    )
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Hoş geldiniz mesajı
                    welcomeSection
                    
                    // Eşinizin aktivitesi
                    if let partnerActivity = partnerActivity {
                        partnerActivitySection(activity: partnerActivity)
                    }
                    
                    // Okumaya devam et
                    if !currentlyReadingBooks.isEmpty {
                        currentlyReadingSection
                    }
                    
                    // Son bitirilen kitaplar
                    if !recentlyFinishedBooks.isEmpty {
                        recentlyFinishedSection
                    }
                    
                    // Okuma istatistikleri
                    readingStatsSection
                    
                    // Motivasyon rozetleri
                    achievementsSection
                }
                .padding()
            }
            .navigationTitle("Ana Sayfa")
            .searchable(text: $searchText, prompt: "Kitap ara")
            .onAppear {
                // Demo verilerini yükleme (gerçek uygulamada Firebase'den veri çekilecek)
                loadDemoData()
            }
        }
    }
    
    // Demo verilerini yükleme
    private func loadDemoData() {
        currentlyReadingBooks = demoCurrentlyReading
        recentlyFinishedBooks = demoRecentlyFinished
        partnerActivity = demoPartnerActivity
    }
    
    // MARK: - UI Bileşenleri
    
    private var welcomeSection: some View {
        VStack(alignment: .leading) {
            Text("Merhaba, \(authViewModel.currentUser?.name ?? "Okuyucu")!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Bugün ne okuyorsun?")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 5)
        .padding(.bottom, 10)
    }
    
    private func partnerActivitySection(activity: PartnerActivity) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Eşinizin Son Aktivitesi")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "person.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text(activity.partnerName)
                        .fontWeight(.medium)
                    
                    Text("\(activity.activityDescription) • \(activity.formattedTime)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    private var currentlyReadingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Okumaya Devam Et")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(currentlyReadingBooks) { book in
                        NavigationLink(destination: BookDetailView(book: book)) {
                            BookCardView(book: book)
                                .frame(width: 160, height: 240)
                        }
                    }
                }
            }
        }
    }
    
    private var recentlyFinishedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Son Bitirdiğin Kitaplar")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(recentlyFinishedBooks) { book in
                        NavigationLink(destination: BookDetailView(book: book)) {
                            BookCardView(book: book)
                                .frame(width: 160, height: 240)
                        }
                    }
                }
            }
        }
    }
    
    private var readingStatsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Okuma İstatistikleri")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack {
                StatCardView(
                    iconName: "book.fill",
                    value: "2",
                    label: "Mevcut Kitaplar",
                    color: .blue
                )
                
                StatCardView(
                    iconName: "checkmark.circle.fill",
                    value: "5",
                    label: "Tamamlanan",
                    color: .green
                )
                
                StatCardView(
                    iconName: "flame.fill",
                    value: "3",
                    label: "Günlük Seri",
                    color: .orange
                )
            }
        }
    }
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Son Kazandığın Rozetler")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    AchievementBadgeView(
                        iconName: "book.fill",
                        title: "Kitap Kurdu",
                        description: "5 kitap okuduğun için"
                    )
                    
                    AchievementBadgeView(
                        iconName: "flame.fill",
                        title: "Seri Okuyucu",
                        description: "3 günlük okuma serisi"
                    )
                    
                    AchievementBadgeView(
                        iconName: "star.fill",
                        title: "İlk Derecelendirme",
                        description: "İlk kitap değerlendirmen"
                    )
                }
            }
        }
    }
}

// MARK: - Yardımcı Yapılar ve Görünümler

struct StatCardView: View {
    let iconName: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack {
            Image(systemName: iconName)
                .font(.title)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

struct AchievementBadgeView: View {
    let iconName: String
    let title: String
    let description: String
    
    var body: some View {
        VStack {
            Image(systemName: iconName)
                .font(.largeTitle)
                .foregroundColor(.yellow)
                .padding()
                .background(Color.yellow.opacity(0.2))
                .clipShape(Circle())
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 120, height: 160)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

struct BookCardView: View {
    let book: Book
    
    var body: some View {
        VStack(alignment: .leading) {
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
                    .frame(width: 120, height: 160)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 160)
                        .overlay(
                            Text(book.title)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .padding(5)
                        )
                }
            }
            .cornerRadius(8)
            .shadow(radius: 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(book.author)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // İlerleme çubuğu
                if !book.isCompleted {
                    ProgressView(value: book.readingProgress, total: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(height: 5)
                    
                    Text("\(Int(book.readingProgress))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 5)
        }
        .padding(10)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// Partner aktivitesini temsil eden sınıf
struct PartnerActivity {
    let partnerName: String
    let bookTitle: String
    let activityType: ActivityType
    let timestamp: Date
    
    enum ActivityType {
        case startedReading
        case finishedReading
        case addedNote
        case setGoal
    }
    
    var activityDescription: String {
        switch activityType {
        case .startedReading:
            return "\"\(bookTitle)\" kitabını okumaya başladı"
        case .finishedReading:
            return "\"\(bookTitle)\" kitabını tamamladı"
        case .addedNote:
            return "\"\(bookTitle)\" kitabına not ekledi"
        case .setGoal:
            return "Yeni bir okuma hedefi belirledi"
        }
    }
    
    var formattedTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

// Detay sayfası için mockup görünüm
struct BookDetailView: View {
    let book: Book
    
    var body: some View {
        Text("Kitap Detayı: \(book.title)")
            .padding()
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AuthViewModel())
    }
} 