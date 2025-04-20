import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Combine

/// FirebaseManager, uygulamanın Firebase hizmetleriyle etkileşimini yöneten merkezi bir sınıftır.
/// Firebase Authentication, Firestore ve Storage işlemlerini yönetir.
class FirebaseManager {
    // Singleton instance
    static let shared = FirebaseManager()
    
    // Firebase servisleri
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    // Hata günlüğü
    private var errorLogger = ErrorLogger()
    
    // Singleton constructor
    private init() {
        configureFirebase()
    }
    
    // MARK: - Firebase Yapılandırması
    
    /// Firebase'i yapılandırır. Uygulama ilk başlatıldığında çağrılır.
    private func configureFirebase() {
        // FirebaseApp zaten yapılandırılmışsa tekrar yapılandırmayı engelle
        guard FirebaseApp.app() == nil else {
            print("Firebase zaten yapılandırılmış.")
            return
        }
        
        // GoogleService-Info.plist dosyasından yapılandırma
        FirebaseApp.configure()
        
        print("Firebase yapılandırması tamamlandı.")
    }
    
    // MARK: - Kimlik Doğrulama İşlemleri
    
    /// Kullanıcı girişi yapar
    /// - Parameters:
    ///   - email: Kullanıcının e-posta adresi
    ///   - password: Kullanıcının şifresi
    /// - Returns: Giriş yapan kullanıcının bilgilerini içeren bir Publisher
    func loginUser(email: String, password: String) -> AnyPublisher<User, Error> {
        Future<User, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Manager instance is nil"])))
                return
            }
            
            self.auth.signIn(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    self.errorLogger.log(error: error, context: "Authentication error while signing in")
                    promise(.failure(error))
                    return
                }
                
                guard let authResult = authResult else {
                    let error = NSError(domain: "FirebaseManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Authentication result is nil"])
                    self.errorLogger.log(error: error, context: "Unexpected nil authResult during sign in")
                    promise(.failure(error))
                    return
                }
                
                // Firestore'dan kullanıcı profilini getir
                self.fetchUserProfile(userId: authResult.user.uid) { result in
                    switch result {
                    case .success(let userData):
                        // User modeli oluştur
                        var user = User(id: authResult.user.uid, name: userData["name"] as? String ?? "", email: authResult.user.email ?? "")
                        
                        // Ek kullanıcı verilerini ayarla
                        if let profileImageURL = userData["profileImageURL"] as? String {
                            user.profileImageURL = URL(string: profileImageURL)
                        }
                        if let partnerId = userData["partnerId"] as? String {
                            user.partnerId = partnerId
                        }
                        if let partnerName = userData["partnerName"] as? String {
                            user.partnerName = partnerName
                        }
                        
                        // Giriş zamanını güncelle
                        self.updateUserLastLoginTime(userId: authResult.user.uid)
                        
                        promise(.success(user))
                        
                    case .failure(let error):
                        // Kullanıcı verileri getirilemediğinde, sadece temel bilgilerle model oluştur
                        self.errorLogger.log(error: error, context: "Failed to fetch user data during sign in")
                        let user = User(id: authResult.user.uid, name: authResult.user.displayName ?? "", email: authResult.user.email ?? "")
                        promise(.success(user))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    /// Yeni kullanıcı kaydı yapar
    /// - Parameters:
    ///   - email: Yeni kullanıcının e-posta adresi
    ///   - password: Yeni kullanıcının şifresi
    ///   - name: Yeni kullanıcının adı
    /// - Returns: Kaydedilen kullanıcının bilgilerini içeren bir Publisher
    func registerUser(email: String, password: String, name: String) -> AnyPublisher<User, Error> {
        Future<User, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Manager instance is nil"])))
                return
            }
            
            self.auth.createUser(withEmail: email, password: password) { authResult, error in
                if let error = error {
                    self.errorLogger.log(error: error, context: "Authentication error while registering")
                    promise(.failure(error))
                    return
                }
                
                guard let authResult = authResult else {
                    let error = NSError(domain: "FirebaseManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Authentication result is nil"])
                    self.errorLogger.log(error: error, context: "Unexpected nil authResult during registration")
                    promise(.failure(error))
                    return
                }
                
                // Kullanıcı profilini güncelle
                let changeRequest = authResult.user.createProfileChangeRequest()
                changeRequest.displayName = name
                
                changeRequest.commitChanges { [weak self] error in
                    if let error = error {
                        self?.errorLogger.log(error: error, context: "Error updating user display name")
                    }
                    
                    // Kayıt tarihi olarak şu anki zamanı kullan
                    let userData: [String: Any] = [
                        "name": name,
                        "email": email,
                        "dateJoined": FieldValue.serverTimestamp(),
                        "lastLogin": FieldValue.serverTimestamp()
                    ]
                    
                    // Firestore'a kullanıcı verilerini kaydet
                    self?.db.collection("users").document(authResult.user.uid).setData(userData) { error in
                        if let error = error {
                            self?.errorLogger.log(error: error, context: "Error saving user data to Firestore")
                            // Hata olsa bile, kullanıcıyı kaydettik, sadece verilerini kaydedemedik
                            let user = User(id: authResult.user.uid, name: name, email: email)
                            promise(.success(user))
                            return
                        }
                        
                        // Boş istatistik ve tercihlerle yeni kullanıcı oluştur
                        let user = User(id: authResult.user.uid, name: name, email: email)
                        promise(.success(user))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    /// Kullanıcı çıkışı yapar
    /// - Returns: İşlem sonucunu içeren bir Publisher
    func logoutUser() -> AnyPublisher<Void, Error> {
        Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Manager instance is nil"])))
                return
            }
            
            do {
                try self.auth.signOut()
                promise(.success(()))
            } catch {
                self.errorLogger.log(error: error, context: "Error while signing out")
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    /// Şifre sıfırlama e-postası gönderir
    /// - Parameter email: Şifresi sıfırlanacak kullanıcının e-posta adresi
    /// - Returns: İşlem sonucunu içeren bir Publisher
    func resetPassword(email: String) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Manager instance is nil"])))
                return
            }
            
            self.auth.sendPasswordReset(withEmail: email) { error in
                if let error = error {
                    self.errorLogger.log(error: error, context: "Error sending password reset email")
                    promise(.failure(error))
                    return
                }
                
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }
    
    /// Mevcut kullanıcının kimliğini alır
    /// - Returns: Kullanıcı kimliği veya nil
    func getCurrentUserId() -> String? {
        return auth.currentUser?.uid
    }
    
    // MARK: - Firestore İşlemleri
    
    /// Kullanıcı profilini Firestore'dan getirir
    /// - Parameters:
    ///   - userId: Kullanıcı kimliği
    ///   - completion: İşlem tamamlandığında çağrılacak closure
    private func fetchUserProfile(userId: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        db.collection("users").document(userId).getDocument { documentSnapshot, error in
            if let error = error {
                self.errorLogger.log(error: error, context: "Error fetching user profile")
                completion(.failure(error))
                return
            }
            
            guard let document = documentSnapshot, document.exists, let userData = document.data() else {
                let error = NSError(domain: "FirebaseManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "User document does not exist"])
                self.errorLogger.log(error: error, context: "User document not found")
                completion(.failure(error))
                return
            }
            
            completion(.success(userData))
        }
    }
    
    /// Kullanıcının son giriş zamanını günceller
    /// - Parameter userId: Kullanıcı kimliği
    private func updateUserLastLoginTime(userId: String) {
        db.collection("users").document(userId).updateData([
            "lastLogin": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                self.errorLogger.log(error: error, context: "Error updating last login time")
            }
        }
    }
    
    // MARK: - Kitap İşlemleri
    
    /// Kitapları Firestore'dan getirir
    /// - Parameters:
    ///   - userId: Kullanıcı kimliği
    ///   - completion: İşlem tamamlandığında çağrılacak closure
    func fetchBooks(userId: String, completion: @escaping (Result<[Book], Error>) -> Void) {
        db.collection("users").document(userId).collection("books").getDocuments { querySnapshot, error in
            if let error = error {
                self.errorLogger.log(error: error, context: "Error fetching books")
                completion(.failure(error))
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                completion(.success([]))
                return
            }
            
            let books = documents.compactMap { document -> Book? in
                guard let title = document.data()["title"] as? String,
                      let author = document.data()["author"] as? String else {
                    return nil
                }
                
                // Kitap verilerini ayrıştır
                let id = document.documentID
                let isbn = document.data()["isbn"] as? String
                let pageCount = document.data()["pageCount"] as? Int ?? 0
                let currentPage = document.data()["currentPage"] as? Int ?? 0
                
                let dateAdded = (document.data()["dateAdded"] as? Timestamp)?.dateValue() ?? Date()
                let dateFinished = (document.data()["dateFinished"] as? Timestamp)?.dateValue()
                
                let genre = document.data()["genre"] as? String
                let notes = document.data()["notes"] as? String
                let isFavorite = document.data()["isFavorite"] as? Bool ?? false
                let rating = document.data()["rating"] as? Int
                
                var coverURL: URL? = nil
                if let coverURLString = document.data()["coverURL"] as? String {
                    coverURL = URL(string: coverURLString)
                }
                
                let book = Book(
                    id: id,
                    title: title,
                    author: author,
                    coverURL: coverURL,
                    isbn: isbn,
                    pageCount: pageCount,
                    currentPage: currentPage,
                    dateAdded: dateAdded,
                    dateFinished: dateFinished,
                    genre: genre,
                    notes: notes,
                    isFavorite: isFavorite,
                    rating: rating
                )
                
                return book
            }
            
            completion(.success(books))
        }
    }
    
    /// Kitabı Firestore'a kaydeder
    /// - Parameters:
    ///   - book: Kaydedilecek kitap
    ///   - userId: Kullanıcı kimliği
    ///   - completion: İşlem tamamlandığında çağrılacak closure
    func saveBook(book: Book, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Kitap verilerini hazırla
        var bookData: [String: Any] = [
            "title": book.title,
            "author": book.author,
            "isbn": book.isbn ?? "",
            "pageCount": book.pageCount,
            "currentPage": book.currentPage,
            "dateAdded": book.dateAdded,
            "isFavorite": book.isFavorite
        ]
        
        if let dateFinished = book.dateFinished {
            bookData["dateFinished"] = dateFinished
        }
        
        if let genre = book.genre {
            bookData["genre"] = genre
        }
        
        if let notes = book.notes {
            bookData["notes"] = notes
        }
        
        if let rating = book.rating {
            bookData["rating"] = rating
        }
        
        // Kitap ID'si olmayan yeni bir kitapsa, ID oluştur
        let bookId = book.id ?? UUID().uuidString
        
        // Kapak resmi varsa, Storage'a yükle
        if let coverURL = book.coverURL {
            uploadBookCover(userId: userId, bookId: bookId, coverURL: coverURL) { result in
                switch result {
                case .success(let downloadURL):
                    bookData["coverURL"] = downloadURL.absoluteString
                    
                    // Kitabı Firestore'a kaydet
                    self.saveBookData(userId: userId, bookId: bookId, bookData: bookData, completion: completion)
                    
                case .failure(let error):
                    // Kapak yükleme hatası olsa bile kitabı kaydetmeye devam et
                    self.errorLogger.log(error: error, context: "Error uploading book cover")
                    self.saveBookData(userId: userId, bookId: bookId, bookData: bookData, completion: completion)
                }
            }
        } else {
            // Kapak resmi yoksa, doğrudan kaydet
            saveBookData(userId: userId, bookId: bookId, bookData: bookData, completion: completion)
        }
    }
    
    /// Kitap verilerini Firestore'a kaydeder
    /// - Parameters:
    ///   - userId: Kullanıcı kimliği
    ///   - bookId: Kitap kimliği
    ///   - bookData: Kitap verileri
    ///   - completion: İşlem tamamlandığında çağrılacak closure
    private func saveBookData(userId: String, bookId: String, bookData: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("users").document(userId).collection("books").document(bookId).setData(bookData) { error in
            if let error = error {
                self.errorLogger.log(error: error, context: "Error saving book data")
                completion(.failure(error))
                return
            }
            
            completion(.success(()))
        }
    }
    
    /// Kitabı Firestore'dan siler
    /// - Parameters:
    ///   - bookId: Silinecek kitap kimliği
    ///   - userId: Kullanıcı kimliği
    ///   - completion: İşlem tamamlandığında çağrılacak closure
    func deleteBook(bookId: String, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // Kitabı Firestore'dan sil
        db.collection("users").document(userId).collection("books").document(bookId).delete { error in
            if let error = error {
                self.errorLogger.log(error: error, context: "Error deleting book")
                completion(.failure(error))
                return
            }
            
            // Kitap kapağını Storage'dan sil
            self.deleteBookCover(userId: userId, bookId: bookId) { _ in
                // Kapak silme hatası olsa bile işlemi başarılı kabul et
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Storage İşlemleri
    
    /// Kitap kapağını Storage'a yükler
    /// - Parameters:
    ///   - userId: Kullanıcı kimliği
    ///   - bookId: Kitap kimliği
    ///   - coverURL: Kapak resmi URL'si
    ///   - completion: İşlem tamamlandığında çağrılacak closure
    private func uploadBookCover(userId: String, bookId: String, coverURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        // Kapak resmi referansını oluştur
        let storageRef = storage.reference().child("users/\(userId)/books/\(bookId)/cover.jpg")
        
        // URL'den veriyi indir
        URLSession.shared.dataTask(with: coverURL) { data, response, error in
            if let error = error {
                self.errorLogger.log(error: error, context: "Error downloading cover image from URL")
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: "FirebaseManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "No data received from cover URL"])
                self.errorLogger.log(error: error, context: "No data received from cover URL")
                completion(.failure(error))
                return
            }
            
            // Storage'a yükle
            storageRef.putData(data, metadata: nil) { _, error in
                if let error = error {
                    self.errorLogger.log(error: error, context: "Error uploading cover image to Storage")
                    completion(.failure(error))
                    return
                }
                
                // İndirme URL'sini al
                storageRef.downloadURL { url, error in
                    if let error = error {
                        self.errorLogger.log(error: error, context: "Error getting download URL")
                        completion(.failure(error))
                        return
                    }
                    
                    guard let downloadURL = url else {
                        let error = NSError(domain: "FirebaseManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Download URL is nil"])
                        self.errorLogger.log(error: error, context: "Download URL is nil")
                        completion(.failure(error))
                        return
                    }
                    
                    completion(.success(downloadURL))
                }
            }
        }.resume()
    }
    
    /// Kitap kapağını Storage'dan siler
    /// - Parameters:
    ///   - userId: Kullanıcı kimliği
    ///   - bookId: Kitap kimliği
    ///   - completion: İşlem tamamlandığında çağrılacak closure
    private func deleteBookCover(userId: String, bookId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let storageRef = storage.reference().child("users/\(userId)/books/\(bookId)/cover.jpg")
        
        storageRef.delete { error in
            if let error = error {
                // Dosya bulunamadı hatasını görmezden gel
                if (error as NSError).domain == StorageErrorDomain && 
                   (error as NSError).code == StorageErrorCode.objectNotFound.rawValue {
                    completion(.success(()))
                    return
                }
                
                self.errorLogger.log(error: error, context: "Error deleting cover image")
                completion(.failure(error))
                return
            }
            
            completion(.success(()))
        }
    }
}

/// Hata günlüğü sınıfı
class ErrorLogger {
    /// Hatayı günlüğe kaydeder
    /// - Parameters:
    ///   - error: Kaydedilecek hata
    ///   - context: Hata bağlamı
    func log(error: Error, context: String) {
        #if DEBUG
        print("📕 FirebaseManager Error: \(context): \(error.localizedDescription)")
        #endif
        
        // Gerçek uygulamada, Firebase Crashlytics veya başka bir uzak günlük servisi kullanılabilir
    }
} 