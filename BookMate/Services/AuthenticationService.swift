import Foundation
import Combine

enum AuthenticationError: Error, LocalizedError {
    case invalidCredentials
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "E-posta veya şifre hatalı."
        case .emailAlreadyInUse:
            return "Bu e-posta adresi zaten kullanılıyor."
        case .weakPassword:
            return "Şifre çok zayıf. En az 6 karakter olmalı."
        case .networkError:
            return "Bağlantı hatası. İnternet bağlantınızı kontrol edin."
        case .unknown:
            return "Beklenmeyen bir hata oluştu. Lütfen daha sonra tekrar deneyin."
        }
    }
}

struct LoginCredentials {
    let email: String
    let password: String
}

struct RegistrationDetails {
    let email: String
    let password: String
    let name: String
}

// AuthenticationService protokolü, farklı kimlik doğrulama sistemleri için ortak bir arayüz sağlar
protocol AuthenticationService {
    func login(with credentials: LoginCredentials) -> AnyPublisher<User, AuthenticationError>
    func register(with details: RegistrationDetails) -> AnyPublisher<User, AuthenticationError>
    func logout() -> AnyPublisher<Void, AuthenticationError>
    func getCurrentUserId() -> String?
}

// LocalAuthenticationService, yerel veritabanı tabanlı kimlik doğrulama sağlar
class LocalAuthenticationService: AuthenticationService {
    private let dataManager = CoreDataManager.shared
    private let userDefaults = UserDefaults.standard
    
    private let currentUserIdKey = "currentUserId"
    
    func login(with credentials: LoginCredentials) -> AnyPublisher<User, AuthenticationError> {
        return Future<User, AuthenticationError> { promise in
            // Gerçek uygulamada şifre hash'leri kontrol edilir
            // Şimdilik sadece email ile kullanıcı arıyoruz
            
            // Tüm kullanıcıları al
            let users = self.getAllUsers()
            
            // E-postaya göre kullanıcıyı bul
            if let user = users.first(where: { $0.email.lowercased() == credentials.email.lowercased() }) {
                // Gerçek uygulamada şifre hash'i kontrol edilir, burada basitçe geçiyoruz
                // Bu noktada kullanıcı başarıyla giriş yapmış olur
                
                // Geçerli kullanıcı ID'sini kaydet
                self.userDefaults.set(user.id, forKey: self.currentUserIdKey)
                
                promise(.success(user))
            } else {
                promise(.failure(.invalidCredentials))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func register(with details: RegistrationDetails) -> AnyPublisher<User, AuthenticationError> {
        return Future<User, AuthenticationError> { promise in
            // Şifre kontrolü
            if details.password.count < 6 {
                promise(.failure(.weakPassword))
                return
            }
            
            // Tüm kullanıcıları al
            let users = self.getAllUsers()
            
            // E-posta adresi zaten kullanımda mı?
            if users.contains(where: { $0.email.lowercased() == details.email.lowercased() }) {
                promise(.failure(.emailAlreadyInUse))
                return
            }
            
            // Yeni kullanıcı oluştur
            let newUserId = UUID().uuidString
            let newUser = User(
                id: newUserId,
                name: details.name,
                email: details.email,
                statistics: UserStatistics(),
                preferences: UserPreferences(),
                achievements: Achievement.defaultAchievements
            )
            
            // Kullanıcıyı veritabanına kaydet
            self.dataManager.saveUser(newUser)
            
            // Gerçek uygulamada şifre güvenli bir şekilde saklanır
            // Şimdilik şifreyi kaydetmiyoruz
            
            // Geçerli kullanıcı ID'sini kaydet
            self.userDefaults.set(newUserId, forKey: self.currentUserIdKey)
            
            promise(.success(newUser))
        }
        .eraseToAnyPublisher()
    }
    
    func logout() -> AnyPublisher<Void, AuthenticationError> {
        return Future<Void, AuthenticationError> { promise in
            // Oturum bilgilerini temizle
            self.userDefaults.removeObject(forKey: self.currentUserIdKey)
            
            promise(.success(()))
        }
        .eraseToAnyPublisher()
    }
    
    func getCurrentUserId() -> String? {
        return userDefaults.string(forKey: currentUserIdKey)
    }
    
    // Tüm kullanıcıları getir (gerçek uygulamada bu işlev farklı olabilir)
    private func getAllUsers() -> [User] {
        // Normalde tüm kullanıcıları getirmek için API veya veritabanı kullanılır
        // Şimdilik basit bir yaklaşım kullanıyoruz
        
        // Bu fonksiyon gerçek bir uygulamada veritabanından tüm kullanıcıları çeker
        // Şimdilik test için örnek bir kullanıcı döndürelim
        let testUser = User(
            id: "test_user_id",
            name: "Test Kullanıcı",
            email: "test@example.com",
            statistics: UserStatistics(),
            preferences: UserPreferences(),
            achievements: Achievement.defaultAchievements
        )
        
        return [testUser]
    }
}

// Kimlik doğrulama durumunu yöneten sınıf
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    private let authService: AuthenticationService
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var error: AuthenticationError?
    
    private init(authService: AuthenticationService = LocalAuthenticationService()) {
        self.authService = authService
        
        // Uygulamanın başlangıcında oturum durumunu kontrol et
        checkAuthenticationState()
    }
    
    private func checkAuthenticationState() {
        if let userId = authService.getCurrentUserId() {
            isAuthenticated = true
            
            // Kullanıcı verilerini yükle
            loadUser(userId: userId)
        } else {
            isAuthenticated = false
            currentUser = nil
        }
    }
    
    private func loadUser(userId: String) {
        isLoading = true
        
        // Core Data'dan kullanıcıyı yükle
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let user = CoreDataManager.shared.fetchUser(id: userId)
            
            DispatchQueue.main.async {
                self.currentUser = user
                self.isLoading = false
            }
        }
    }
    
    func login(email: String, password: String) {
        isLoading = true
        error = nil
        
        let credentials = LoginCredentials(email: email, password: password)
        
        authService.login(with: credentials)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.error = error
                    }
                },
                receiveValue: { [weak self] user in
                    self?.isAuthenticated = true
                    self?.currentUser = user
                }
            )
            .store(in: &cancellables)
    }
    
    func register(name: String, email: String, password: String) {
        isLoading = true
        error = nil
        
        let details = RegistrationDetails(name: name, email: email, password: password)
        
        authService.register(with: details)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.error = error
                    }
                },
                receiveValue: { [weak self] user in
                    self?.isAuthenticated = true
                    self?.currentUser = user
                }
            )
            .store(in: &cancellables)
    }
    
    func logout() {
        isLoading = true
        error = nil
        
        authService.logout()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.error = error
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.isAuthenticated = false
                    self?.currentUser = nil
                }
            )
            .store(in: &cancellables)
    }
} 