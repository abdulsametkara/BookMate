import Foundation
import Combine

class FirebaseAuthenticationService: AuthenticationService {
    private let firebaseManager = FirebaseManager.shared
    private let userDefaults = UserDefaults.standard
    
    private let currentUserIdKey = "currentUserId"
    
    func login(with credentials: LoginCredentials) -> AnyPublisher<User, AuthenticationError> {
        return firebaseManager.loginUser(email: credentials.email, password: credentials.password)
            .mapError { error -> AuthenticationError in
                // Firebase hata kodlarına göre dönüştürme yap
                if error.localizedDescription.contains("password is invalid") ||
                   error.localizedDescription.contains("no user record") {
                    return .invalidCredentials
                } else if error.localizedDescription.contains("network error") {
                    return .networkError
                } else {
                    print("Firebase giriş hatası: \(error.localizedDescription)")
                    return .unknown
                }
            }
            .handleEvents(receiveOutput: { [weak self] user in
                // Başarılı girişte kullanıcı kimliğini yerel depolamaya kaydet
                self?.userDefaults.set(user.id, forKey: self?.currentUserIdKey ?? "")
                
                // Core Data'ya da senkronize et
                CoreDataManager.shared.saveUser(user)
            })
            .eraseToAnyPublisher()
    }
    
    func register(with details: RegistrationDetails) -> AnyPublisher<User, AuthenticationError> {
        return firebaseManager.registerUser(email: details.email, password: details.password, name: details.name)
            .mapError { error -> AuthenticationError in
                // Firebase hata kodlarına göre dönüştürme yap
                if error.localizedDescription.contains("email address is already in use") {
                    return .emailAlreadyInUse
                } else if error.localizedDescription.contains("password is invalid") ||
                          error.localizedDescription.contains("weak password") {
                    return .weakPassword
                } else if error.localizedDescription.contains("network error") {
                    return .networkError
                } else {
                    print("Firebase kayıt hatası: \(error.localizedDescription)")
                    return .unknown
                }
            }
            .handleEvents(receiveOutput: { [weak self] user in
                // Başarılı kayıtta kullanıcı kimliğini yerel depolamaya kaydet
                self?.userDefaults.set(user.id, forKey: self?.currentUserIdKey ?? "")
                
                // Core Data'ya da senkronize et
                CoreDataManager.shared.saveUser(user)
            })
            .eraseToAnyPublisher()
    }
    
    func logout() -> AnyPublisher<Void, AuthenticationError> {
        return firebaseManager.logoutUser()
            .mapError { error -> AuthenticationError in
                print("Firebase çıkış hatası: \(error.localizedDescription)")
                return .unknown
            }
            .handleEvents(receiveOutput: { [weak self] _ in
                // Kullanıcı kimliğini yerel depolamadan kaldır
                self?.userDefaults.removeObject(forKey: self?.currentUserIdKey ?? "")
            })
            .eraseToAnyPublisher()
    }
    
    func getCurrentUserId() -> String? {
        return userDefaults.string(forKey: currentUserIdKey)
    }
} 