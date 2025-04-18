import Foundation
import Combine

class UserViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isLoggedIn: Bool = false
    
    init() {
        loadSampleUser()
    }
    
    private func loadSampleUser() {
        let sampleUser = User(
            id: "current_user_id",
            username: "AhmetYılmaz",
            email: "ahmet@example.com",
            profileImageUrl: nil,
            bio: "Kitap okumayı seven ve eşimle birlikte okuma deneyimini paylaşmaktan keyif alan biriyim.",
            joinDate: Date().addingTimeInterval(-90*24*60*60), // 90 gün önce
            lastActive: Date(),
            favoriteGenres: ["Klasik", "Bilim Kurgu", "Fantastik"],
            readingGoal: ReadingGoal(
                type: .booksPerYear,
                target: 24,
                progress: 8,
                startDate: Date().startOfYear,
                endDate: Date().endOfYear
            ),
            statistics: ReadingStatistics(
                totalBooksRead: 32,
                booksReadThisMonth: 2,
                booksReadThisYear: 8,
                totalPagesRead: 9870,
                pagesReadThisMonth: 450,
                averageRating: 4.2,
                favoriteTopic: "Tarih",
                readingStreak: 14,
                longestStreak: 21
            ),
            partnerId: "partner_user_id",
            partnerUsername: "AyşeYılmaz",
            partnerProfileImageUrl: nil,
            isPartnershipActive: true,
            appTheme: .system,
            notificationsEnabled: true,
            privacySettings: PrivacySettings(
                shareReadingProgress: true,
                shareNotes: true,
                shareStats: true,
                shareActivity: true
            )
        )
        
        self.currentUser = sampleUser
        self.isLoggedIn = true
    }
    
    func updateUserName(_ name: String) {
        guard var user = currentUser else { return }
        user.username = name
        currentUser = user
    }
} 