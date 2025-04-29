import Foundation
import Combine

class UserViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isLoggedIn: Bool = false
    
    init() {
        // Kayıtlı kullanıcıyı kontrol et
        if UserSession.shared.isLoggedIn {
            currentUser = UserSession.shared.getCurrentUser()
            isLoggedIn = true
        } else {
            // Test için örnek kullanıcı yüklenmesi iptal edildi
            // loadSampleUser()
        }
    }
    
    // Örnek kullanıcı - Sadece geliştirme aşamasında kullanılır
    private func loadSampleUser() {
        // Tamamen yeni User nesnesi oluşturalım
        var sampleUser = User(
            username: "AhmetYılmaz",
            email: "ahmet@example.com",
            password: "sample123", // Örnek şifre
            joinDate: Date().addingTimeInterval(-90*24*60*60), // 90 gün önce
            lastActive: Date(),
            isPartnershipActive: true,
            appTheme: .system,
            notificationsEnabled: true, 
            privacySettings: PrivacySettings()
        )
        
        // Opsiyonel alanları sonradan doldur
        sampleUser.fullName = "Ahmet Yılmaz"
        sampleUser.profileImageURL = "https://example.com/profile.jpg"
        sampleUser.bio = "Kitap okumayı seven ve eşimle birlikte okuma deneyimini paylaşmaktan keyif alan biriyim."
        sampleUser.favoriteGenres = ["Klasik", "Bilim Kurgu", "Fantastik"]
        sampleUser.readingGoal = ReadingGoal(
            type: .booksPerYear,
            target: 24,
            progress: 8,
            startDate: Date().startOfYear,
            endDate: Date().endOfYear
        )
        sampleUser.statistics = ReadingStatistics(
            totalBooksRead: 32,
            booksReadThisMonth: 2,
            booksReadThisYear: 8,
            totalPagesRead: 9870,
            pagesReadThisMonth: 450,
            averageRating: 4.2,
            favoriteTopic: "Tarih",
            readingStreak: 14,
            longestStreak: 21
        )
        sampleUser.partnerId = "partner_user_id"
        sampleUser.partnerUsername = "AyşeYılmaz"
        // Doğru şekilde partnerProfileImageUrl URL tipinde olmalı
        sampleUser.partnerProfileImageUrl = URL(string: "https://example.com/partner_profile.jpg")
        
        self.currentUser = sampleUser
        self.isLoggedIn = true
    }
    
    // Kullanıcı bilgilerini güncelle
    func updateUserName(_ name: String) {
        guard var user = currentUser else { return }
        user.username = name
        currentUser = user
        // Kullanıcı bilgilerini UserSession'a kaydet
        UserSession.shared.saveUser(user)
    }
    
    // Kullanıcı bilgilerini yenile
    func refreshUserData() {
        if UserSession.shared.isLoggedIn {
            currentUser = UserSession.shared.getCurrentUser()
            isLoggedIn = true
        } else {
            currentUser = nil
            isLoggedIn = false
        }
    }
    
    // Kullanıcı istatistiklerini güncelle
    func updateUserStatistics(with bookViewModel: BookViewModel) {
        guard var currentUser = self.currentUser else { return }
        
        // Kullanıcının istatistiklerini oluşturalım veya güncelleyelim
        var stats = currentUser.statistics ?? ReadingStatistics()
        
        // Tamamlanan kitap sayısı + şu an okunmakta olan kitaplar
        let totalRelevantBooks = bookViewModel.completedBooks.count + bookViewModel.currentlyReadingBooks.count
        stats.totalBooksRead = totalRelevantBooks
        
        // Bu ayki okunan kitap sayısı
        let thisMonth = Calendar.current.component(.month, from: Date())
        let thisYear = Calendar.current.component(.year, from: Date())
        let booksThisMonth = bookViewModel.completedBooks.filter { book in
            guard let finishedDate = book.finishedReading else { return false }
            let month = Calendar.current.component(.month, from: finishedDate)
            let year = Calendar.current.component(.year, from: finishedDate)
            return month == thisMonth && year == thisYear
        }
        stats.booksReadThisMonth = booksThisMonth.count
        
        // Bu yıl okunan kitap sayısı
        let booksThisYear = bookViewModel.completedBooks.filter { book in
            guard let finishedDate = book.finishedReading else { return false }
            let year = Calendar.current.component(.year, from: finishedDate)
            return year == thisYear
        }
        stats.booksReadThisYear = booksThisYear.count
        
        // Toplam okunan sayfa sayısı - Yeni hesaplama
        var totalPages = 0
        
        // Tamamlanan kitapların sayfaları
        for book in bookViewModel.completedBooks {
            if let pageCount = book.pageCount {
                totalPages += pageCount
            }
        }
        
        // Şu anda okunan kitapların ilerleme sayfaları
        for book in bookViewModel.currentlyReadingBooks {
            if let currentPage = book.currentPage, currentPage > 0 {
                totalPages += currentPage
            }
        }
        
        // Debug için yazdırma
        print("Toplam okunan sayfa: \(totalPages)")
        print("Okunan kitap sayısı: \(totalRelevantBooks)")
        
        stats.totalPagesRead = totalPages
        
        // Bu ay okunan sayfa sayısı
        var pagesThisMonth = 0
        
        // Bu ay tamamlanan kitapların sayfaları
        for book in booksThisMonth {
            if let pageCount = book.pageCount {
                pagesThisMonth += pageCount
            }
        }
        
        // Şu an okunan kitapların bu ay içinde okunan sayfaları
        let now = Date()
        let firstDayOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: now))!
        
        for book in bookViewModel.currentlyReadingBooks {
            if let currentPage = book.currentPage,
               let lastReadAt = book.lastReadAt,
               lastReadAt >= firstDayOfMonth,
               currentPage > 0 {
                pagesThisMonth += currentPage
            }
        }
        
        stats.pagesReadThisMonth = pagesThisMonth
        
        // Ortalama puan hesaplama (yalnızca tamamlanan kitaplar için)
        var totalRating = 0.0
        var ratedBooksCount = 0
        
        // Önce debug için yazdırma
        for book in bookViewModel.completedBooks {
            print("Kitap: \(book.title), Puan: \(book.userRating ?? 0)")
        }
        
        for book in bookViewModel.completedBooks {
            if let rating = book.userRating, rating > 0 {
                totalRating += Double(rating)
                ratedBooksCount += 1
            }
        }
        
        // Debug için yazdırma
        print("Toplam puan: \(totalRating), Puanlanan kitap sayısı: \(ratedBooksCount)")
        
        if ratedBooksCount > 0 {
            stats.averageRating = totalRating / Double(ratedBooksCount)
        } else {
            stats.averageRating = 0.0
        }
        
        // Debug için yazdırma
        print("Hesaplanan ortalama puan: \(stats.averageRating)")
        
        // Favori konu (en çok okunan kategori)
        var categoryCount: [String: Int] = [:]
        for book in bookViewModel.completedBooks {
            if let categories = book.categories {
                for category in categories {
                    categoryCount[category, default: 0] += 1
                }
            }
        }
        
        stats.favoriteTopic = categoryCount.max(by: { $0.value < $1.value })?.key ?? "Genel"
        
        // Okuma serisi güncellenmiyor şu an, bu değeri örnek olarak sabit tutuyoruz
        if stats.readingStreak <= 0 {
            stats.readingStreak = 25
        }
        if stats.longestStreak <= 0 {
            stats.longestStreak = 30
        }
        
        // İstatistikleri kullanıcıya atayalım ve kaydedelim
        currentUser.statistics = stats
        
        // Güncel kullanıcıyı kaydedelim
        self.currentUser = currentUser
        UserSession.shared.saveUser(currentUser)
        
        // Değişiklikleri bildirmek için objectWillChange'i tetikle
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    // Kullanıcı profil bilgilerini güncelleme
    func updateUserProfile(_ updatedUser: User) {
        // UserSession aracılığıyla güncelleme
        self.currentUser = updatedUser
        UserSession.shared.saveUser(updatedUser)
        
        // Güncelleme sonrası dinleyicilere bildirim
        objectWillChange.send()
    }
} 