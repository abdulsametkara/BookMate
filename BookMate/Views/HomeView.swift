import SwiftUI

struct HomeView: View {
    @EnvironmentObject var bookViewModel: BookViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    
    @State private var showingSearchSheet = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Ana içerik
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Kullanıcı karşılama
                        welcomeSection
                        
                        // Okuma durumu kartı
                        readingStatusCard
                        
                        // Şu anda okunanlar
                        currentlyReadingSection
                        
                        // Son eklenenler
                        recentlyAddedSection
                        
                        // Partner aktivitesi
                        if userViewModel.currentUser?.hasPartner == true {
                            partnerActivitySection
                        }
                        
                        // Önerilen kitaplar
                        recommendedBooksSection
                    }
                    .padding(.horizontal)
                }
                
                // Alt menü
                bottomTabBar
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Image("app_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 28)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSearchSheet = true
                    }) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showingSearchSheet) {
                SearchView(bookViewModel: bookViewModel)
            }
            .onAppear {
                bookViewModel.fetchUserLibrary()
                bookViewModel.fetchPartnerSharedBooks()
            }
        }
    }
    
    // MARK: - Özel bileşenler
    
    // Karşılama bölümü
    private var welcomeSection: some View {
        VStack(alignment: .leading) {
            if let user = userViewModel.currentUser {
                Text("Merhaba, \(user.username)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                if let goal = user.readingGoal, !goal.isCompleted {
                    HStack {
                        Text("Hedefinize \(goal.remainingDays) gün kaldı:")
                            .font(.subheadline)
                        
                        Text("\(goal.progress)/\(goal.target) \(goal.type.description.lowercased())")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    ProgressBar(value: goal.progressPercentage/100)
                        .frame(height: 8)
                        .padding(.top, 4)
                }
            } else {
                Text("Merhaba!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
        }
        .padding(.top)
    }
    
    // Okuma durumu kartı
    private var readingStatusCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Okuma durumu")
                        .font(.headline)
                    
                    let stats = userViewModel.currentUser?.statistics ?? ReadingStatistics()
                    Text("\(stats.readingStreak) günlük seri 🔥")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                NavigationLink(destination: StatisticsView(userViewModel: userViewModel)) {
                    Text("Detaylar")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            HStack(spacing: 12) {
                // Bugünün istatistiği
                StatCard(
                    title: "Bugün",
                    value: "\(userViewModel.currentUser?.readingGoal?.currentDayMinutes ?? 0) dk",
                    icon: "clock",
                    color: .blue
                )
                
                // Toplam okunan
                StatCard(
                    title: "Toplam",
                    value: "\(userViewModel.currentUser?.statistics.totalBooksRead ?? 0) kitap",
                    icon: "book.closed",
                    color: .green
                )
                
                // Yıl içinde
                StatCard(
                    title: "Bu yıl",
                    value: "\(userViewModel.currentUser?.statistics.booksReadThisYear ?? 0) kitap",
                    icon: "calendar",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // Şu anda okunanlar
    private var currentlyReadingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Şu Anda Okuduklarım", showAll: true) {
                NavigationLink(destination: BookListView(
                    books: bookViewModel.currentlyReadingBooks,
                    title: "Şu Anda Okuduklarım",
                    bookViewModel: bookViewModel
                )) {
                    EmptyView()
                }
            }
            
            if bookViewModel.currentlyReadingBooks.isEmpty {
                EmptyStateView(
                    message: "Şu anda okuduğunuz kitap yok",
                    buttonText: "Kitap Ekle",
                    icon: "book.fill"
                ) {
                    showingSearchSheet = true
                }
                .frame(height: 180)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(bookViewModel.currentlyReadingBooks) { book in
                            NavigationLink(destination: BookDetailView(book: book, bookViewModel: bookViewModel)) {
                                ReadingBookCard(book: book)
                                    .frame(width: 280, height: 160)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
    
    // Son eklenen kitaplar
    private var recentlyAddedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Son Eklenenler", showAll: true) {
                NavigationLink(destination: BookListView(
                    books: bookViewModel.recentlyAddedBooks,
                    title: "Son Eklenenler",
                    bookViewModel: bookViewModel
                )) {
                    EmptyView()
                }
            }
            
            if bookViewModel.recentlyAddedBooks.isEmpty {
                EmptyStateView(
                    message: "Henüz kitap eklemediniz",
                    buttonText: "Kitap Ekle", 
                    icon: "plus.circle"
                ) {
                    showingSearchSheet = true
                }
                .frame(height: 160)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(bookViewModel.recentlyAddedBooks) { book in
                            NavigationLink(destination: BookDetailView(book: book, bookViewModel: bookViewModel)) {
                                BookCoverView(book: book)
                                    .frame(width: 120, height: 160)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
    
    // Partner aktiviteleri
    private var partnerActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Partner Aktivitesi", showAll: true) {
                NavigationLink(destination: PartnerActivityView(userViewModel: userViewModel)) {
                    EmptyView()
                }
            }
            
            if userViewModel.partnerActivities.isEmpty {
                EmptyStateView(
                    message: "Henüz partner aktivitesi yok",
                    icon: "person.2"
                )
                .frame(height: 120)
            } else {
                VStack(spacing: 12) {
                    ForEach(userViewModel.partnerActivities.prefix(2)) { activity in
                        ActivityRow(activity: activity)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    // Önerilen kitaplar
    private var recommendedBooksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Sizin İçin Önerilenler", showAll: false)
            
            if bookViewModel.recommendedBooks.isEmpty {
                EmptyStateView(
                    message: "Tüm öneri listenizi okudunuz",
                    icon: "star.fill"
                )
                .frame(height: 160)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(bookViewModel.recommendedBooks) { book in
                            NavigationLink(destination: BookDetailView(book: book, bookViewModel: bookViewModel)) {
                                VStack(alignment: .leading) {
                                    BookCoverView(book: book)
                                        .frame(width: 120, height: 160)
                                    
                                    if let recommendedBy = book.recommendedBy {
                                        Text("\(recommendedBy) önerdi")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
    
    // Alt gezinme çubuğu
    private var bottomTabBar: some View {
        HStack {
            TabBarButton(
                title: "Ana Sayfa",
                icon: "house",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }
            
            TabBarButton(
                title: "Kitaplık",
                icon: "books.vertical",
                isSelected: selectedTab == 1
            ) {
                selectedTab = 1
            }
            
            TabBarButton(
                title: "Koleksiyonlar",
                icon: "rectangle.stack",
                isSelected: selectedTab == 2
            ) {
                selectedTab = 2
            }
            
            TabBarButton(
                title: "Profil",
                icon: "person",
                isSelected: selectedTab == 3
            ) {
                selectedTab = 3
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray5)),
            alignment: .top
        )
    }
}

// MARK: - Yardımcı görünümler

struct SectionHeader: View {
    let title: String
    let showAll: Bool
    var action: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            
            Spacer()
            
            if showAll {
                Button(action: {
                    action?()
                }) {
                    Text("Tümünü Gör")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ReadingBookCard: View {
    let book: Book
    
    var body: some View {
        HStack(spacing: 16) {
            BookCoverView(book: book)
                .frame(width: 80, height: 120)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(book.formattedAuthors)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Sayfa \(book.currentPage)/\(book.pageCount ?? 0)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(book.readingProgressPercentage))%")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    ProgressBar(value: book.readingProgressPercentage/100)
                        .frame(height: 8)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct BookCoverView: View {
    let book: Book
    
    var body: some View {
        Group {
            if let url = book.coverImageUrl {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        fallbackCover
                    @unknown default:
                        fallbackCover
                    }
                }
            } else {
                fallbackCover
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 2)
    }
    
    var fallbackCover: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: generateGradientColors()),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack {
                Text(book.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .foregroundColor(.white)
                
                if let authors = book.authors, !authors.isEmpty {
                    Text(authors.first ?? "")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(8)
        }
    }
    
    // Her kitap için farklı bir arka plan gradyanı oluştur
    private func generateGradientColors() -> [Color] {
        let colors: [[Color]] = [
            [.blue, .purple],
            [.green, .blue],
            [.orange, .red],
            [.purple, .pink],
            [.indigo, .blue]
        ]
        
        // Kitap ID'sine göre rastgele ama tutarlı bir renk seç
        let hashValue = abs(book.id.hashValue % colors.count)
        return colors[hashValue]
    }
}

struct ActivityRow: View {
    let activity: Activity
    
    var body: some View {
        HStack(spacing: 12) {
            // Profil resmi
            UserAvatarView(url: activity.userProfileImageUrl, size: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                // Aktivite açıklaması
                Text(activity.activityDescription)
                    .font(.subheadline)
                
                // Tarih
                Text(activity.formattedTimestamp)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Kitap kapağı (varsa)
            if activity.type.involvesBook, let coverUrl = activity.bookCoverImageUrl {
                AsyncImage(url: coverUrl) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 40, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
        }
    }
}

// Aktivite tipinin kitapla ilgili olup olmadığını kontrol et
extension ActivityType {
    var involvesBook: Bool {
        switch self {
        case .startedReading, .finishedReading, .updatedProgress, 
             .addedBook, .ratedBook, .addedNote:
            return true
        case .achievedGoal, .joinedApp, .connectedWithPartner:
            return false
        }
    }
}

struct UserAvatarView: View {
    let url: URL?
    let size: CGFloat
    
    var body: some View {
        Group {
            if let url = url {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        defaultAvatar
                    }
                }
            } else {
                defaultAvatar
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
    
    var defaultAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.2))
            
            Image(systemName: "person.fill")
                .foregroundColor(.blue)
                .font(.system(size: size * 0.5))
        }
    }
}

struct ProgressBar: View {
    let value: Double // 0 ve 1 arasında bir değer
    var color: Color = .blue
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                
                Rectangle()
                    .fill(color)
                    .frame(width: min(CGFloat(value) * geometry.size.width, geometry.size.width))
            }
            .cornerRadius(10)
        }
    }
}

struct EmptyStateView: View {
    let message: String
    var buttonText: String? = nil
    let icon: String
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.gray)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let buttonText = buttonText, let action = action {
                Button(action: action) {
                    Text(buttonText)
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct TabBarButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .blue : .gray)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Önizleme
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let bookViewModel = BookViewModel()
        let userViewModel = UserViewModel()
        
        HomeView(bookViewModel: bookViewModel, userViewModel: userViewModel)
    }
} 