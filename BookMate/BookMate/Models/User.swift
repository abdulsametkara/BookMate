import Foundation

struct User: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var username: String
    var email: String
    var password: String // Gerçek uygulamada hash'lenmeli
    var dateJoined: Date = Date()
    
    // Opsiyonel profil bilgileri
    var fullName: String?
    var profileImageURL: String?
    var favoriteGenres: [String]?
    
    var profileImageUrl: URL? {
        if let urlString = profileImageURL {
            return URL(string: urlString)
        }
        return nil
    }
    
    var bio: String?
    var joinDate: Date
    var lastActive: Date
    
    var readingGoal: ReadingGoal?
    var statistics: ReadingStatistics?
    
    var partnerId: String?
    var partnerUsername: String?
    var partnerProfileImageUrl: URL?
    var isPartnershipActive: Bool
    
    var appTheme: AppTheme
    var notificationsEnabled: Bool
    var privacySettings: PrivacySettings
    
    var hasPartner: Bool {
        return partnerId != nil && isPartnershipActive
    }
    
    // Computed properties for UI
    var displayName: String {
        return username
    }
    
    var profilePhotoURL: String? {
        if let imageURL = profileImageURL, let url = URL(string: imageURL) {
            return url.absoluteString
        }
        return nil
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
}

// Kullanıcı oturumu için yardımcı sınıf
class UserSession {
    static let shared = UserSession()
    
    private let userDefaultsKey = "currentUser"
    private let isLoggedInKey = "isLoggedIn"
    
    private init() {}
    
    // Kullanıcı oturumunu kaydetme
    func saveUser(_ user: User, password: String? = nil) {
        var userToSave = user
        
        // Eğer password parametresi gönderilmişse, kullanıcının şifresini güncelle
        if let password = password {
            userToSave.password = password
        }
        
        do {
            let encoder = JSONEncoder()
            let userData = try encoder.encode(userToSave)
            UserDefaults.standard.set(userData, forKey: userDefaultsKey)
            UserDefaults.standard.set(true, forKey: isLoggedInKey)
        } catch {
            print("Kullanıcı kaydedilirken hata: \(error.localizedDescription)")
        }
    }
    
    // Mevcut oturum açmış kullanıcıyı alma
    func getCurrentUser() -> User? {
        guard let userData = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let user = try decoder.decode(User.self, from: userData)
            return user
        } catch {
            print("Kullanıcı yüklenirken hata: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Kullanıcının giriş yapıp yapmadığını kontrol etme
    var isLoggedIn: Bool {
        return UserDefaults.standard.bool(forKey: isLoggedInKey)
    }
    
    // Oturumu kapatma
    func logout() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.set(false, forKey: isLoggedInKey)
    }
} 