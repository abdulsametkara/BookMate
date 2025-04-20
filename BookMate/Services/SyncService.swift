import Foundation
import Combine
import CoreData

/// Veri senkronizasyon servisi, Core Data ile Firebase arasındaki veri akışını yönetir
/// ve çevrimdışı modda çalışabilmesini sağlar.
class SyncService {
    // Singleton instance
    static let shared = SyncService()
    
    // Servisler
    private let firebaseManager = FirebaseManager.shared
    private let coreDataManager = CoreDataManager.shared
    
    // Senkronizasyon durumu
    private var isSyncing = false
    private var lastSyncDate: Date?
    private var syncErrors: [Error] = []
    
    // Senkronizasyon için Publishers
    private var cancellables = Set<AnyCancellable>()
    
    // Çevrimdışı işlem kuyruğu - senkronizasyon için bekleyen işlemler
    private var pendingOperations: [SyncOperation] = []
    
    private init() {
        // Uygulama başladığında kaydedilmiş senkronizasyon durumunu yükle
        loadSyncState()
    }
    
    // MARK: - Public Methods
    
    /// Tüm veriyi senkronize eder
    /// - Returns: Senkronizasyon sonucunu içeren bir Publisher
    func syncAll() -> AnyPublisher<SyncResult, Error> {
        // Zaten senkronizasyon çalışıyorsa, işlemi engelle
        guard !isSyncing else {
            return Fail(error: SyncError.alreadySyncing).eraseToAnyPublisher()
        }
        
        return Future<SyncResult, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(SyncError.serviceNotAvailable))
                return
            }
            
            self.isSyncing = true
            
            // Senkronizasyon işlemi başladı
            print("Veri senkronizasyonu başladı...")
            
            // Adım 1: Bekleyen işlemleri yükle ve işle
            self.processPendingOperations()
                .flatMap { _ -> AnyPublisher<Void, Error> in
                    // Adım 2: Kullanıcı verilerini senkronize et
                    if let userId = self.firebaseManager.getCurrentUserId() {
                        return self.syncUserData(userId: userId)
                    } else {
                        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
                    }
                }
                .flatMap { _ -> AnyPublisher<Void, Error> in
                    // Adım 3: Kitapları senkronize et
                    if let userId = self.firebaseManager.getCurrentUserId() {
                        return self.syncBooks(userId: userId)
                    } else {
                        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
                    }
                }
                .sink(
                    receiveCompletion: { completion in
                        self.isSyncing = false
                        
                        switch completion {
                        case .finished:
                            // Senkronizasyon başarılı
                            self.lastSyncDate = Date()
                            self.saveSyncState()
                            
                            let result = SyncResult(
                                success: true,
                                lastSyncDate: self.lastSyncDate,
                                syncedItems: self.pendingOperations.count,
                                errors: []
                            )
                            
                            self.pendingOperations.removeAll()
                            self.savePendingOperations()
                            
                            promise(.success(result))
                            
                        case .failure(let error):
                            // Senkronizasyon hatası
                            self.syncErrors.append(error)
                            self.saveSyncState()
                            
                            let result = SyncResult(
                                success: false,
                                lastSyncDate: self.lastSyncDate,
                                syncedItems: 0,
                                errors: [error]
                            )
                            
                            promise(.success(result))
                        }
                    },
                    receiveValue: { _ in }
                )
                .store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }
    
    /// Çevrimdışı moddayken kitap ekler
    /// - Parameters:
    ///   - book: Eklenecek kitap
    ///   - userId: Kullanıcı kimliği
    func addBookOffline(book: Book, userId: String) {
        // Kitabı Core Data'ya kaydet
        coreDataManager.saveBook(book)
        
        // Senkronizasyon kuyruğuna ekle
        let operation = SyncOperation(
            type: .addBook,
            itemId: book.id ?? UUID().uuidString,
            userId: userId,
            data: try? JSONEncoder().encode(book),
            createdAt: Date()
        )
        
        pendingOperations.append(operation)
        savePendingOperations()
    }
    
    /// Çevrimdışı moddayken kitap günceller
    /// - Parameters:
    ///   - book: Güncellenecek kitap
    ///   - userId: Kullanıcı kimliği
    func updateBookOffline(book: Book, userId: String) {
        // Kitabı Core Data'ya kaydet
        coreDataManager.saveBook(book)
        
        // Senkronizasyon kuyruğuna ekle
        let operation = SyncOperation(
            type: .updateBook,
            itemId: book.id ?? "",
            userId: userId,
            data: try? JSONEncoder().encode(book),
            createdAt: Date()
        )
        
        pendingOperations.append(operation)
        savePendingOperations()
    }
    
    /// Çevrimdışı moddayken kitap siler
    /// - Parameters:
    ///   - bookId: Silinecek kitap kimliği
    ///   - userId: Kullanıcı kimliği
    func deleteBookOffline(bookId: String, userId: String) {
        // Kitabı Core Data'dan sil
        coreDataManager.deleteBook(id: bookId)
        
        // Senkronizasyon kuyruğuna ekle
        let operation = SyncOperation(
            type: .deleteBook,
            itemId: bookId,
            userId: userId,
            data: nil,
            createdAt: Date()
        )
        
        pendingOperations.append(operation)
        savePendingOperations()
    }
    
    // MARK: - Private Sync Methods
    
    /// Bekleyen işlemleri işler
    /// - Returns: İşlem sonucunu içeren bir Publisher
    private func processPendingOperations() -> AnyPublisher<Void, Error> {
        guard !pendingOperations.isEmpty else {
            return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        
        // Her bir operasyonu işlemek için
        let publishers = pendingOperations.map { operation -> AnyPublisher<Void, Error> in
            switch operation.type {
            case .addBook, .updateBook:
                guard let data = operation.data,
                      let book = try? JSONDecoder().decode(Book.self, from: data) else {
                    return Fail(error: SyncError.invalidData).eraseToAnyPublisher()
                }
                
                return Future<Void, Error> { promise in
                    self.firebaseManager.saveBook(book: book, userId: operation.userId) { result in
                        switch result {
                        case .success:
                            promise(.success(()))
                        case .failure(let error):
                            promise(.failure(error))
                        }
                    }
                }.eraseToAnyPublisher()
                
            case .deleteBook:
                return Future<Void, Error> { promise in
                    self.firebaseManager.deleteBook(bookId: operation.itemId, userId: operation.userId) { result in
                        switch result {
                        case .success:
                            promise(.success(()))
                        case .failure(let error):
                            promise(.failure(error))
                        }
                    }
                }.eraseToAnyPublisher()
                
            case .updateUser:
                // Kullanıcı güncelleme işlemleri burada eklenebilir
                return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
        }
        
        // Tüm işlemleri sırayla çalıştır
        return Publishers.Sequence(sequence: publishers)
            .flatMap(maxPublishers: .max(1)) { $0 }
            .collect()
            .map { _ in () }
            .eraseToAnyPublisher()
    }
    
    /// Kullanıcı verilerini senkronize eder
    /// - Parameter userId: Kullanıcı kimliği
    /// - Returns: İşlem sonucunu içeren bir Publisher
    private func syncUserData(userId: String) -> AnyPublisher<Void, Error> {
        // Kullanıcı verilerini Firebase'den al ve Core Data'ya kaydet
        // Gelecek uygulamada ek kodlar eklenebilir
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    /// Kitapları senkronize eder
    /// - Parameter userId: Kullanıcı kimliği
    /// - Returns: İşlem sonucunu içeren bir Publisher
    private func syncBooks(userId: String) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            // Firebase'den kitapları getir
            self.firebaseManager.fetchBooks(userId: userId) { result in
                switch result {
                case .success(let serverBooks):
                    // Core Data'daki kitapları getir
                    let localBooks = self.coreDataManager.fetchBooks()
                    
                    // Kitapları senkronize et
                    self.reconcileBooks(localBooks: localBooks, serverBooks: serverBooks)
                    
                    // Core Data'ya kaydet
                    for book in serverBooks {
                        self.coreDataManager.saveBook(book)
                    }
                    
                    promise(.success(()))
                    
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    /// Yerel ve sunucu kitapları arasındaki çakışmaları çözer
    /// - Parameters:
    ///   - localBooks: Yerel kitaplar
    ///   - serverBooks: Sunucudaki kitaplar
    private func reconcileBooks(localBooks: [Book], serverBooks: [Book]) {
        let localIds = Set(localBooks.compactMap { $0.id })
        let serverIds = Set(serverBooks.compactMap { $0.id })
        
        // Yerel olan ama sunucuda olmayan kitapları senkronize et
        let localOnlyIds = localIds.subtracting(serverIds)
        for id in localOnlyIds {
            if let book = localBooks.first(where: { $0.id == id }),
               let userId = book.userId {
                // Kitabı sunucuya ekleyecek işlem
                let operation = SyncOperation(
                    type: .addBook,
                    itemId: id,
                    userId: userId,
                    data: try? JSONEncoder().encode(book),
                    createdAt: Date()
                )
                pendingOperations.append(operation)
            }
        }
        
        // Güncelleme çakışmalarını çöz
        for serverBook in serverBooks {
            if let serverBookId = serverBook.id,
               let localBook = localBooks.first(where: { $0.id == serverBookId }),
               let localUpdate = localBook.dateUpdated,
               let serverUpdate = serverBook.dateUpdated,
               localUpdate > serverUpdate {
                
                // Yerel kitap daha yeni, sunucuya gönder
                if let userId = localBook.userId {
                    let operation = SyncOperation(
                        type: .updateBook,
                        itemId: serverBookId,
                        userId: userId,
                        data: try? JSONEncoder().encode(localBook),
                        createdAt: Date()
                    )
                    pendingOperations.append(operation)
                }
            }
        }
        
        savePendingOperations()
    }
    
    // MARK: - Persistence Methods
    
    /// Senkronizasyon durumunu yükler
    private func loadSyncState() {
        if let lastSyncDate = UserDefaults.standard.object(forKey: "LastSyncDate") as? Date {
            self.lastSyncDate = lastSyncDate
        }
        
        loadPendingOperations()
    }
    
    /// Senkronizasyon durumunu kaydeder
    private func saveSyncState() {
        UserDefaults.standard.set(lastSyncDate, forKey: "LastSyncDate")
    }
    
    /// Bekleyen işlemleri yükler
    private func loadPendingOperations() {
        guard let data = UserDefaults.standard.data(forKey: "PendingOperations") else {
            return
        }
        
        do {
            pendingOperations = try JSONDecoder().decode([SyncOperation].self, from: data)
        } catch {
            print("Bekleyen işlemler yüklenemedi: \(error)")
        }
    }
    
    /// Bekleyen işlemleri kaydeder
    private func savePendingOperations() {
        do {
            let data = try JSONEncoder().encode(pendingOperations)
            UserDefaults.standard.set(data, forKey: "PendingOperations")
        } catch {
            print("Bekleyen işlemler kaydedilemedi: \(error)")
        }
    }
}

// MARK: - Models

/// Senkronizasyon işlemi türleri
enum SyncOperationType: String, Codable {
    case addBook
    case updateBook
    case deleteBook
    case updateUser
}

/// Bekleyen senkronizasyon işlemi
struct SyncOperation: Codable {
    let type: SyncOperationType
    let itemId: String
    let userId: String
    let data: Data?
    let createdAt: Date
}

/// Senkronizasyon sonucu
struct SyncResult {
    let success: Bool
    let lastSyncDate: Date?
    let syncedItems: Int
    let errors: [Error]
}

/// Senkronizasyon hataları
enum SyncError: Error {
    case alreadySyncing
    case serviceNotAvailable
    case invalidData
    case networkError
    case conflictError
    
    var localizedDescription: String {
        switch self {
        case .alreadySyncing:
            return "Senkronizasyon zaten devam ediyor"
        case .serviceNotAvailable:
            return "Senkronizasyon servisi kullanılamıyor"
        case .invalidData:
            return "Geçersiz veri formatı"
        case .networkError:
            return "Ağ bağlantısı hatası"
        case .conflictError:
            return "Veri çakışması"
        }
    }
} 