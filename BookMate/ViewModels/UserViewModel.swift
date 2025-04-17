import Foundation
import Combine

class UserViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var partnerActivities: [ReadingActivity] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let dataManager = CoreDataManager.shared
    
    // Kullanıcı kimliği için basit bir yaklaşım (gerçek uygulamada kimlik doğrulama servisi kullanılır)
    private let currentUserId = "current_user_id"
    
    init() {
        // Kullanıcı kimliğini uygulama genelinde erişilebilir hale getir
        UserDefaults.standard.set(currentUserId, forKey: "currentUserId")
        
        loadUser()
        loadPartnerActivities()
    }
    
    func loadUser() {
        isLoading = true
        
        // Core Data'dan kullanıcıyı yükle
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var user = self.dataManager.fetchUser(id: self.currentUserId)
            
            // Eğer kullanıcı yoksa, yeni bir tane oluştur
            if user == nil {
                user = User.sample
                user?.id = self.currentUserId
                self.dataManager.saveUser(user!)
            }
            
            DispatchQueue.main.async {
                self.currentUser = user
                self.isLoading = false
            }
        }
    }
    
    func updateUser(_ user: User) {
        dataManager.saveUser(user)
        currentUser = user
    }
    
    func updateUserName(_ name: String) {
        guard var user = currentUser else { return }
        user.name = name
        updateUser(user)
    }
    
    func updateUserPreferences(preferences: UserPreferences) {
        guard var user = currentUser else { return }
        user.preferences = preferences
        updateUser(user)
    }
    
    func loadPartnerActivities() {
        isLoading = true
        
        // Kullanıcının eşini kontrol et
        guard let partnerId = currentUser?.partnerId else {
            // Eş yoksa örnek verileri göster
            DispatchQueue.main.async {
                self.partnerActivities = ReadingActivity.samples
                self.isLoading = false
            }
            return
        }
        
        // Core Data'dan eş aktivitelerini yükle
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let activities = self.dataManager.fetchReadingActivities(forUserId: partnerId)
            
            DispatchQueue.main.async {
                self.partnerActivities = activities
                self.isLoading = false
            }
        }
    }
    
    func updateUserStatistics(completedBook book: Book) {
        guard var user = currentUser else { return }
        
        // Kitap istatistiklerini güncelle
        user.statistics.totalBooksRead += 1
        user.statistics.totalPagesRead += book.pageCount
        
        // Haftalık, aylık ve yıllık istatistikler
        user.statistics.booksReadThisWeek += 1
        user.statistics.booksReadThisMonth += 1
        user.statistics.booksReadThisYear += 1
        user.statistics.pagesReadThisWeek += book.pageCount
        user.statistics.pagesReadThisMonth += book.pageCount
        user.statistics.pagesReadThisYear += book.pageCount
        
        // En sevilen tür güncellemesi (basitleştirilmiş)
        if !book.genre.isEmpty {
            user.statistics.favoriteGenre = book.genre
        }
        
        updateUser(user)
        checkAndUpdateAchievements()
    }
    
    func updateReadingStreak(didReadToday: Bool) {
        guard var user = currentUser else { return }
        
        if didReadToday {
            user.statistics.currentReadingStreakDays += 1
            
            // En uzun okuma serisini güncelle
            if user.statistics.currentReadingStreakDays > user.statistics.longestReadingStreakDays {
                user.statistics.longestReadingStreakDays = user.statistics.currentReadingStreakDays
            }
        } else {
            user.statistics.currentReadingStreakDays = 0
        }
        
        updateUser(user)
        checkAndUpdateAchievements()
    }
    
    func updateReadingTime(minutes: Int) {
        guard var user = currentUser else { return }
        
        user.statistics.totalReadingTimeMinutes += minutes
        user.statistics.readingTimeThisWeekMinutes += minutes
        
        // Günlük ortalama okuma süresi (basitleştirilmiş)
        let totalDays = max(1, user.statistics.totalReadingTimeMinutes / (24 * 60))
        user.statistics.averageDailyReadingTimeMinutes = user.statistics.totalReadingTimeMinutes / totalDays
        
        updateUser(user)
    }
    
    func checkAndUpdateAchievements() {
        guard var user = currentUser else { return }
        
        // İlk kitap başarısı
        if user.statistics.totalBooksRead >= 1 {
            unlockAchievement(id: "İlk Kitap")
        }
        
        // 10 Kitap Kulübü başarısı
        if user.statistics.totalBooksRead >= 10 {
            unlockAchievement(id: "10 Kitap Kulübü")
        }
        
        // Haftalık Okuyucu başarısı (basitleştirilmiş)
        if user.statistics.currentReadingStreakDays >= 7 {
            unlockAchievement(id: "Haftalık Okuyucu")
        }
        
        // Diğer başarılar benzer şekilde kontrol edilebilir
        
        updateUser(user)
    }
    
    private func unlockAchievement(id: String) {
        guard var user = currentUser else { return }
        
        if let index = user.achievements.firstIndex(where: { $0.title == id }) {
            if !user.achievements[index].isUnlocked {
                user.achievements[index].isUnlocked = true
                user.achievements[index].unlockedDate = Date()
                
                // Bildirim oluştur
                print("Tebrikler! '\(id)' başarısını kazandınız!")
                
                // Aktivite oluştur
                let activity = ReadingActivity(
                    userId: user.id,
                    userName: user.name,
                    bookId: "",
                    bookTitle: "",
                    activityType: .addedNote,
                    description: "\(id) başarısını kazandı!"
                )
                
                dataManager.saveReadingActivity(activity)
            }
        }
        
        updateUser(user)
    }
    
    func getUnlockedAchievements() -> [Achievement] {
        guard let user = currentUser else { return [] }
        return user.achievements.filter { $0.isUnlocked }
    }
    
    func getLockedAchievements() -> [Achievement] {
        guard let user = currentUser else { return [] }
        return user.achievements.filter { !$0.isUnlocked }
    }
    
    // Eş davet etme işlevi
    func invitePartner(email: String, name: String) {
        guard var user = currentUser else { return }
        
        // Gerçek uygulamada burada e-posta gönderilir
        // Şimdilik sadece kullanıcı bilgilerini güncelliyoruz
        user.partnerEmail = email
        user.partnerName = name
        user.partnerId = "partner_user_id" // Gerçek bir uygulama için rastgele ID üretilir
        
        updateUser(user)
        
        // Eşleşme aktivitesi oluştur
        let activity = ReadingActivity(
            userId: user.id,
            userName: user.name,
            bookId: "",
            bookTitle: "",
            activityType: .addedNote,
            description: "\(name) ile eşleşti!"
        )
        
        dataManager.saveReadingActivity(activity)
    }
} 