import Foundation
import Combine
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    // Yerel veritabanı olarak UserDefaults kullanacağız
    private let usersKey = "registeredUsers"
    
    init() {
        // Uygulama başladığında, kullanıcının oturum durumunu kontrol et
        checkAuthStatus()
    }
    
    // Oturum durumunu kontrol et
    private func checkAuthStatus() {
        isAuthenticated = UserSession.shared.isLoggedIn
        currentUser = UserSession.shared.getCurrentUser()
    }
    
    // Kullanıcı kaydı
    func register(username: String, email: String, password: String, passwordConfirm: String, fullName: String = "", bio: String = "") {
        isLoading = true
        errorMessage = nil
        
        // Validasyon kontrolleri
        guard !username.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Lütfen tüm alanları doldurun"
            isLoading = false
            return
        }
        
        guard !fullName.isEmpty else {
            errorMessage = "Lütfen isim ve soyisminizi girin"
            isLoading = false
            return
        }
        
        guard password == passwordConfirm else {
            errorMessage = "Şifreler eşleşmiyor"
            isLoading = false
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Şifre en az 6 karakter olmalıdır"
            isLoading = false
            return
        }
        
        guard isValidEmail(email) else {
            errorMessage = "Geçerli bir e-posta adresi girin"
            isLoading = false
            return
        }
        
        // Mevcut kullanıcıları kontrol et
        var users = getRegisteredUsers()
        
        // Kullanıcı adı veya email zaten kullanılıyor mu?
        if users.contains(where: { $0.username == username }) {
            errorMessage = "Bu kullanıcı adı zaten kullanılıyor"
            isLoading = false
            return
        }
        
        if users.contains(where: { $0.email == email }) {
            errorMessage = "Bu e-posta adresi zaten kullanılıyor"
            isLoading = false
            return
        }
        
        // Yeni kullanıcı oluştur
        var newUser = User(
            username: username,
            email: email,
            password: password,
            joinDate: Date(),
            lastActive: Date(),
            isPartnershipActive: false,
            appTheme: .system,  // AppTheme varsayılan değeri
            notificationsEnabled: true,
            privacySettings: .default  // PrivacySettings varsayılan değeri
        )
        
        // Opsiyonel alanları doldur
        if !fullName.isEmpty {
            newUser.fullName = fullName
        }
        
        if !bio.isEmpty {
            newUser.bio = bio
        }
        
        // Temel okuma istatistiklerini ve hedeflerini oluştur
        newUser.statistics = ReadingStatistics(
            totalBooksRead: 0,
            booksReadThisMonth: 0, 
            booksReadThisYear: 0,
            totalPagesRead: 0,
            pagesReadThisMonth: 0,
            averageRating: 0,
            favoriteTopic: "",
            readingStreak: 0,
            longestStreak: 0
        )
        
        // Yıllık kitap hedefi
        newUser.readingGoal = ReadingGoal(
            type: .booksPerYear,
            target: 12, 
            progress: 0,
            startDate: Date().startOfYear,
            endDate: Date().endOfYear
        )
        
        // Kullanıcıyı kaydet
        users.append(newUser)
        saveRegisteredUsers(users)
        
        // Otomatik giriş yap
        self.currentUser = newUser
        UserSession.shared.saveUser(newUser)
        self.isAuthenticated = true
        
        isLoading = false
    }
    
    // Kullanıcı girişi
    func login(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        // Validasyon
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Lütfen e-posta ve şifre girin"
            isLoading = false
            return
        }
        
        // Kayıtlı kullanıcıları al
        let users = getRegisteredUsers()
        
        // E-posta ve şifre ile eşleşen kullanıcıyı bul
        if let user = users.first(where: { $0.email == email && $0.password == password }) {
            // Kullanıcı bulundu, oturum aç
            self.currentUser = user
            UserSession.shared.saveUser(user)
            self.isAuthenticated = true
            
            // Son aktif tarihi güncelle
            var updatedUser = user
            updatedUser.lastActive = Date()
            updateUserInStorage(updatedUser)
        } else {
            // Kullanıcı bulunamadı
            errorMessage = "E-posta veya şifre hatalı"
        }
        
        isLoading = false
    }
    
    // Kullanıcıyı veritabanında güncelle
    private func updateUserInStorage(_ user: User) {
        var users = getRegisteredUsers()
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users[index] = user
            saveRegisteredUsers(users)
        }
    }
    
    // Çıkış yap
    func logout() {
        UserSession.shared.logout()
        currentUser = nil
        isAuthenticated = false
    }
    
    // Kayıtlı kullanıcıları al
    private func getRegisteredUsers() -> [User] {
        guard let data = UserDefaults.standard.data(forKey: usersKey) else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([User].self, from: data)
        } catch {
            print("Kullanıcılar yüklenirken hata: \(error.localizedDescription)")
            return []
        }
    }
    
    // Kullanıcıları kaydet
    private func saveRegisteredUsers(_ users: [User]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(users)
            UserDefaults.standard.set(data, forKey: usersKey)
        } catch {
            print("Kullanıcılar kaydedilirken hata: \(error.localizedDescription)")
        }
    }
    
    // E-posta formatı kontrolü
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    // Şifre güncelleme
    func updatePassword(currentPassword: String, newPassword: String) -> Bool {
        guard let user = currentUser else { return false }
        
        // Mevcut şifreyi doğrula
        if user.password != currentPassword {
            return false
        }
        
        // Yeni şifreyi ayarla
        var updatedUser = user
        updatedUser.password = newPassword
        
        // Kullanıcıyı güncelle
        currentUser = updatedUser
        UserSession.shared.saveUser(updatedUser)
        
        // Veritabanında güncelle
        updateUserInStorage(updatedUser)
        
        return true
    }
    
    // Hesap silme
    func deleteAccount() {
        guard let user = currentUser else { return }
        
        // Kayıtlı kullanıcılar listesinden sil
        var users = getRegisteredUsers()
        users.removeAll { $0.id == user.id }
        saveRegisteredUsers(users)
        
        // Oturumu kapat
        logout()
    }
} 