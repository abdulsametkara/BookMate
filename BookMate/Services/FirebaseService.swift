import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class FirebaseService {
    // Singleton instance
    static let shared = FirebaseService()
    
    // Firebase hizmetleri
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    // Koleksiyon referansları
    private let usersCollection = "users"
    private let booksCollection = "books"
    private let couplesCollection = "couples"
    
    private init() {
        configureFirebase()
    }
    
    // Firebase yapılandırması
    private func configureFirebase() {
        guard FirebaseApp.app() == nil else {
            print("Firebase zaten yapılandırılmış.")
            return
        }
        
        // Gerçek uygulamada, Google-Info.plist'den otomatik yapılandırma kullanılmalı
        let firebaseOptions = FirebaseOptions(
            googleAppID: "1:123456789012:ios:abcdef1234567890",
            gcmSenderID: "123456789012"
        )
        firebaseOptions.apiKey = "AIzaSyBq3Gij7ytDQJ9Z_kFULnQMmMsZ9XXX_XXX"
        firebaseOptions.projectID = "bookmate-app"
        firebaseOptions.storageBucket = "bookmate-app.appspot.com"
        
        FirebaseApp.configure(options: firebaseOptions)
        print("Firebase yapılandırması tamamlandı.")
    }
    
    // MARK: - Kimlik Doğrulama
    
    func createUser(email: String, password: String) async throws -> User {
        let authDataResult = try await Auth.auth().createUser(withEmail: email, password: password)
        return authDataResult.user
    }
    
    func signIn(email: String, password: String) async throws -> User {
        let authDataResult = try await Auth.auth().signIn(withEmail: email, password: password)
        return authDataResult.user
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    func getCurrentUser() -> User? {
        return Auth.auth().currentUser
    }
    
    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
    // MARK: - Kullanıcı Profili
    
    func createUserProfile(userId: String, displayName: String, email: String) async throws {
        let userData: [String: Any] = [
            "displayName": displayName,
            "email": email,
            "createdAt": FieldValue.serverTimestamp(),
            "lastLogin": FieldValue.serverTimestamp()
        ]
        
        try await db.collection("users").document(userId).setData(userData)
    }
    
    func getUserProfile(userId: String) async throws -> [String: Any]? {
        let document = try await db.collection("users").document(userId).getDocument()
        return document.exists ? document.data() : nil
    }
    
    func updateUserProfile(userId: String, data: [String: Any]) async throws {
        try await db.collection("users").document(userId).updateData(data)
    }
    
    // MARK: - Kitap Koleksiyonu
    
    func saveBook(userId: String, book: Book) async throws {
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
        
        // Kapak resmi varsa, Storage'a yükle ve URL'i kaydet
        if let coverURL = book.coverURL {
            if let coverImageURL = try await uploadBookCover(userId: userId, bookId: book.id, coverURL: coverURL) {
                bookData["coverURL"] = coverImageURL.absoluteString
            }
        }
        
        try await db.collection("users").document(userId).collection("books").document(book.id).setData(bookData)
    }
    
    func getBooks(userId: String) async throws -> [Book] {
        let querySnapshot = try await db.collection("users").document(userId).collection("books").getDocuments()
        
        var books: [Book] = []
        
        for document in querySnapshot.documents {
            let data = document.data()
            
            guard let title = data["title"] as? String,
                  let author = data["author"] as? String else {
                continue
            }
            
            let id = document.documentID
            let isbn = data["isbn"] as? String
            let pageCount = data["pageCount"] as? Int ?? 0
            let currentPage = data["currentPage"] as? Int ?? 0
            
            let dateAdded = (data["dateAdded"] as? Timestamp)?.dateValue() ?? Date()
            let dateFinished = (data["dateFinished"] as? Timestamp)?.dateValue()
            
            let genre = data["genre"] as? String
            let notes = data["notes"] as? String
            let isFavorite = data["isFavorite"] as? Bool ?? false
            let rating = data["rating"] as? Int
            
            var coverURL: URL? = nil
            if let coverURLString = data["coverURL"] as? String {
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
            
            books.append(book)
        }
        
        return books
    }
    
    func updateBook(userId: String, book: Book) async throws {
        try await saveBook(userId: userId, book: book)
    }
    
    func deleteBook(userId: String, bookId: String) async throws {
        try await db.collection("users").document(userId).collection("books").document(bookId).delete()
        
        // İlişkili kapak resmini sil
        try await deleteBookCover(userId: userId, bookId: bookId)
    }
    
    // MARK: - Veri Senkronizasyonu
    
    func listenForBookChanges(userId: String, completion: @escaping ([Book]) -> Void) -> ListenerRegistration {
        return db.collection("users").document(userId).collection("books")
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Snapshot dinleme hatası: \(error?.localizedDescription ?? "Bilinmeyen hata")")
                    return
                }
                
                var books: [Book] = []
                
                for document in documents {
                    let data = document.data()
                    
                    guard let title = data["title"] as? String,
                          let author = data["author"] as? String else {
                        continue
                    }
                    
                    let id = document.documentID
                    let isbn = data["isbn"] as? String
                    let pageCount = data["pageCount"] as? Int ?? 0
                    let currentPage = data["currentPage"] as? Int ?? 0
                    
                    let dateAdded = (data["dateAdded"] as? Timestamp)?.dateValue() ?? Date()
                    let dateFinished = (data["dateFinished"] as? Timestamp)?.dateValue()
                    
                    let genre = data["genre"] as? String
                    let notes = data["notes"] as? String
                    let isFavorite = data["isFavorite"] as? Bool ?? false
                    let rating = data["rating"] as? Int
                    
                    var coverURL: URL? = nil
                    if let coverURLString = data["coverURL"] as? String {
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
                    
                    books.append(book)
                }
                
                completion(books)
            }
    }
    
    // MARK: - Eşleştirme (Coupling)
    
    func sendCoupleRequest(fromUserId: String, toUserEmail: String) async throws {
        // Kullanıcıyı e-posta ile bul
        let querySnapshot = try await db.collection("users")
            .whereField("email", isEqualTo: toUserEmail)
            .getDocuments()
        
        guard let targetUserDoc = querySnapshot.documents.first else {
            throw NSError(domain: "FirebaseService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Bu e-posta adresine sahip kullanıcı bulunamadı."
            ])
        }
        
        let targetUserId = targetUserDoc.documentID
        
        // Eşleştirme isteği gönder
        let requestData: [String: Any] = [
            "fromUserId": fromUserId,
            "status": "pending",
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        try await db.collection("users").document(targetUserId).collection("coupleRequests").document(fromUserId).setData(requestData)
    }
    
    func acceptCoupleRequest(userId: String, requestUserId: String) async throws {
        // İsteği kabul et
        try await db.collection("users").document(userId).collection("coupleRequests").document(requestUserId).updateData([
            "status": "accepted",
            "acceptedAt": FieldValue.serverTimestamp()
        ])
        
        // Her iki kullanıcı için de couple kaydı oluştur
        let coupleData: [String: Any] = [
            "createdAt": FieldValue.serverTimestamp(),
            "status": "active"
        ]
        
        try await db.collection("users").document(userId).collection("couples").document(requestUserId).setData(coupleData)
        try await db.collection("users").document(requestUserId).collection("couples").document(userId).setData(coupleData)
    }
    
    func rejectCoupleRequest(userId: String, requestUserId: String) async throws {
        try await db.collection("users").document(userId).collection("coupleRequests").document(requestUserId).updateData([
            "status": "rejected",
            "rejectedAt": FieldValue.serverTimestamp()
        ])
    }
    
    func getCoupleRequests(userId: String) async throws -> [String: Any] {
        let querySnapshot = try await db.collection("users").document(userId).collection("coupleRequests").getDocuments()
        
        var requests: [String: Any] = [:]
        
        for document in querySnapshot.documents {
            requests[document.documentID] = document.data()
        }
        
        return requests
    }
    
    func getCouple(userId: String) async throws -> [String: Any]? {
        let querySnapshot = try await db.collection("users").document(userId).collection("couples").getDocuments()
        
        // Şu anda sadece tek bir eş destekleniyor
        return querySnapshot.documents.first?.data()
    }
    
    // MARK: - Dosya işlemleri
    
    private func uploadBookCover(userId: String, bookId: String, coverURL: URL) async throws -> URL? {
        let storageRef = storage.reference().child("users/\(userId)/books/\(bookId)/cover.jpg")
        
        // URL'den veriyi indir
        let (data, _) = try await URLSession.shared.data(from: coverURL)
        
        // Storage'a yükle
        _ = try await storageRef.putDataAsync(data)
        
        // İndirme URL'sini al
        return try await storageRef.downloadURL()
    }
    
    private func deleteBookCover(userId: String, bookId: String) async throws {
        let storageRef = storage.reference().child("users/\(userId)/books/\(bookId)/cover.jpg")
        try await storageRef.delete()
    }
} 