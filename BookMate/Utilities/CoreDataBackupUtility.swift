import Foundation
import CoreData

class CoreDataBackupUtility {
    
    // MARK: - Shared Instance
    static let shared = CoreDataBackupUtility()
    
    private init() {}
    
    // MARK: - Backup Methods
    
    /// Kullanıcının Core Data veritabanını yedekler ve JSON dosyası olarak kaydeder
    func backupUserData(userId: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let manager = CoreDataManager.shared
        let context = manager.viewContext
        
        do {
            // Kullanıcıya ait tüm verileri topla
            let userData = try collectUserData(for: userId, context: context)
            
            // JSON'a dönüştür
            let jsonData = try JSONEncoder().encode(userData)
            
            // Dosyayı kaydet
            let backupURL = try saveBackupFile(data: jsonData, userId: userId)
            
            completion(.success(backupURL))
        } catch {
            completion(.failure(error))
        }
    }
    
    /// Yedekten geri yükleme işlemi
    func restoreFromBackup(fileURL: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            // Dosyayı oku
            let data = try Data(contentsOf: fileURL)
            
            // JSON'dan modele dönüştür
            let userData = try JSONDecoder().decode(UserBackupData.self, from: data)
            
            // Verileri Core Data'ya kaydet
            try restoreUserData(userData)
            
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Private Methods
    
    private func collectUserData(for userId: String, context: NSManagedObjectContext) throws -> UserBackupData {
        // Kullanıcı bilgisini al
        let userFetch: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        userFetch.predicate = NSPredicate(format: "id == %@", userId)
        
        guard let user = try context.fetch(userFetch).first else {
            throw BackupError.userNotFound
        }
        
        // Kullanıcının kitaplarını al
        let booksFetch: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        
        // Kullanıcının koleksiyonlarını al
        let collectionsFetch: NSFetchRequest<BookCollectionEntity> = BookCollectionEntity.fetchRequest()
        collectionsFetch.predicate = NSPredicate(format: "ownerId == %@", userId)
        
        // Aktiviteleri al
        let activitiesFetch: NSFetchRequest<ReadingActivityEntity> = ReadingActivityEntity.fetchRequest()
        activitiesFetch.predicate = NSPredicate(format: "userId == %@", userId)
        
        // Ortaklık bilgisini al
        let partnershipFetch: NSFetchRequest<PartnershipEntity> = PartnershipEntity.fetchRequest()
        partnershipFetch.predicate = NSPredicate(format: "userId == %@ OR partnerId == %@", userId, userId)
        
        // Yapıları dönüştür
        let userDTO = mapUserEntityToDTO(user)
        let bookDTOs = try context.fetch(booksFetch).map { mapBookEntityToDTO($0) }
        let collectionDTOs = try context.fetch(collectionsFetch).map { mapCollectionEntityToDTO($0) }
        let activityDTOs = try context.fetch(activitiesFetch).map { mapActivityEntityToDTO($0) }
        let partnershipDTOs = try context.fetch(partnershipFetch).map { mapPartnershipEntityToDTO($0) }
        
        return UserBackupData(
            user: userDTO,
            books: bookDTOs,
            collections: collectionDTOs,
            activities: activityDTOs,
            partnerships: partnershipDTOs
        )
    }
    
    private func saveBackupFile(data: Data, userId: String) throws -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        
        let fileName = "bookmate_backup_\(userId)_\(dateString).json"
        
        let fileManager = FileManager.default
        let documentsURL = try fileManager.url(for: .documentDirectory, 
                                              in: .userDomainMask, 
                                              appropriateFor: nil, 
                                              create: true)
        
        let backupsFolderURL = documentsURL.appendingPathComponent("Backups", isDirectory: true)
        
        // Yedekleme klasörünü oluştur (yoksa)
        if !fileManager.fileExists(atPath: backupsFolderURL.path) {
            try fileManager.createDirectory(at: backupsFolderURL, 
                                           withIntermediateDirectories: true, 
                                           attributes: nil)
        }
        
        let fileURL = backupsFolderURL.appendingPathComponent(fileName)
        try data.write(to: fileURL)
        
        return fileURL
    }
    
    private func restoreUserData(_ userData: UserBackupData) throws {
        let manager = CoreDataManager.shared
        let context = manager.viewContext
        
        // Restore işlemine başlama
        // 1. Kullanıcı verisini restore et
        try restoreUser(userData.user, context: context)
        
        // 2. Kitapları restore et
        for bookDTO in userData.books {
            try restoreBook(bookDTO, context: context)
        }
        
        // 3. Koleksiyonları restore et
        for collectionDTO in userData.collections {
            try restoreCollection(collectionDTO, context: context)
        }
        
        // 4. Aktiviteleri restore et
        for activityDTO in userData.activities {
            try restoreActivity(activityDTO, context: context)
        }
        
        // 5. Ortaklık verilerini restore et
        for partnershipDTO in userData.partnerships {
            try restorePartnership(partnershipDTO, context: context)
        }
        
        // Değişiklikleri kaydet
        try context.save()
    }
    
    // MARK: - Mapping Entities to DTOs
    
    private func mapUserEntityToDTO(_ entity: UserEntity) -> UserDTO {
        // User entity'den DTO oluştur
        return UserDTO(
            id: entity.id ?? "",
            username: entity.username ?? "",
            email: entity.email ?? "",
            profileImageUrl: entity.profileImageUrl,
            bio: entity.bio,
            joinDate: entity.joinDate ?? Date(),
            lastActive: entity.lastActive ?? Date(),
            favoriteGenres: entity.favoriteGenres?.components(separatedBy: ",") ?? [],
            partnerId: entity.partnerId,
            partnerUsername: entity.partnerUsername,
            partnerProfileImageUrl: entity.partnerProfileImageUrl,
            isPartnershipActive: entity.isPartnershipActive,
            notificationsEnabled: entity.notificationsEnabled,
            themePreference: entity.themePreference ?? "system",
            preferencesData: entity.preferencesData,
            privacySettingsData: entity.privacySettingsData,
            statisticsData: entity.statisticsData,
            readingGoalData: entity.readingGoalData
        )
    }
    
    private func mapBookEntityToDTO(_ entity: BookEntity) -> BookDTO {
        return BookDTO(
            id: entity.id ?? "",
            title: entity.title ?? "",
            subtitle: entity.subtitle,
            authors: entity.authors?.components(separatedBy: ",") ?? [],
            isbn: entity.isbn,
            publisher: entity.publisher,
            publishedDate: entity.publishedDate,
            bookDescription: entity.bookDescription,
            language: entity.language,
            categories: entity.categories?.components(separatedBy: ",") ?? [],
            smallThumbnailUrl: entity.smallThumbnailUrl,
            thumbnailUrl: entity.thumbnailUrl,
            pageCount: Int(entity.pageCount),
            dateAdded: entity.dateAdded ?? Date(),
            startedAt: entity.startedAt,
            completedAt: entity.completedAt,
            lastReadAt: entity.lastReadAt,
            currentPage: Int(entity.currentPage),
            readingStatus: entity.readingStatus ?? "",
            isFavorite: entity.isFavorite,
            userRating: entity.userRating,
            userNotes: entity.userNotes,
            isSharedWithPartner: entity.isSharedWithPartner,
            recommendedBy: entity.recommendedBy,
            recommendedDate: entity.recommendedDate,
            partnerNotes: entity.partnerNotes,
            sharedCollectionIds: entity.sharedCollectionIds?.components(separatedBy: ",") ?? [],
            progressData: entity.progressData,
            notesData: entity.notesData,
            highlightsData: entity.highlightsData,
            bookmarksData: entity.bookmarksData,
            readingSessionsData: entity.readingSessionsData,
            readingTime: Int(entity.readingTime),
            lastReadingSessionDate: entity.lastReadingSessionDate
        )
    }
    
    private func mapCollectionEntityToDTO(_ entity: BookCollectionEntity) -> BookCollectionDTO {
        return BookCollectionDTO(
            id: entity.id ?? "",
            name: entity.name ?? "",
            collectionDescription: entity.collectionDescription,
            bookIds: entity.bookIds?.components(separatedBy: ",") ?? [],
            coverUrls: entity.coverUrls?.components(separatedBy: ",") ?? [],
            createdDate: entity.createdDate ?? Date(),
            lastModifiedDate: entity.lastModifiedDate ?? Date(),
            isDefault: entity.isDefault,
            isSharedWithPartner: entity.isSharedWithPartner,
            ownerId: entity.ownerId ?? "",
            ownerUsername: entity.ownerUsername ?? "",
            sortOptionData: entity.sortOptionData,
            filterOptionsData: entity.filterOptionsData
        )
    }
    
    private func mapActivityEntityToDTO(_ entity: ReadingActivityEntity) -> ReadingActivityDTO {
        return ReadingActivityDTO(
            id: entity.id ?? "",
            userId: entity.userId ?? "",
            username: entity.username ?? "",
            bookId: entity.bookId ?? "",
            bookTitle: entity.bookTitle ?? "",
            coverImageUrl: entity.coverImageUrl,
            activityType: entity.activityType ?? "",
            description: entity.description ?? "",
            timestamp: entity.timestamp ?? Date()
        )
    }
    
    private func mapPartnershipEntityToDTO(_ entity: PartnershipEntity) -> PartnershipDTO {
        return PartnershipDTO(
            id: entity.id ?? "",
            userId: entity.userId ?? "",
            partnerId: entity.partnerId ?? "",
            partnerUsername: entity.partnerUsername ?? "",
            status: entity.status ?? "",
            createdAt: entity.createdAt ?? Date(),
            updatedAt: entity.updatedAt ?? Date(),
            lastActivityAt: entity.lastActivityAt,
            sharedBookIds: entity.sharedBookIds?.components(separatedBy: ",") ?? [],
            activityNotificationsData: entity.activityNotificationsData
        )
    }
    
    // MARK: - Restoring Entities from DTOs
    
    private func restoreUser(_ dto: UserDTO, context: NSManagedObjectContext) throws {
        // Mevcut kullanıcıyı kontrol et
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", dto.id)
        
        let userEntity: UserEntity
        
        if let existingUser = try context.fetch(fetchRequest).first {
            userEntity = existingUser
        } else {
            userEntity = UserEntity(context: context)
            userEntity.id = dto.id
        }
        
        // Kullanıcı verilerini doldur
        userEntity.username = dto.username
        userEntity.email = dto.email
        userEntity.profileImageUrl = dto.profileImageUrl
        userEntity.bio = dto.bio
        userEntity.joinDate = dto.joinDate
        userEntity.lastActive = dto.lastActive
        userEntity.favoriteGenres = dto.favoriteGenres.joined(separator: ",")
        userEntity.partnerId = dto.partnerId
        userEntity.partnerUsername = dto.partnerUsername
        userEntity.partnerProfileImageUrl = dto.partnerProfileImageUrl
        userEntity.isPartnershipActive = dto.isPartnershipActive
        userEntity.notificationsEnabled = dto.notificationsEnabled
        userEntity.themePreference = dto.themePreference
        userEntity.preferencesData = dto.preferencesData
        userEntity.privacySettingsData = dto.privacySettingsData
        userEntity.statisticsData = dto.statisticsData
        userEntity.readingGoalData = dto.readingGoalData
    }
    
    private func restoreBook(_ dto: BookDTO, context: NSManagedObjectContext) throws {
        let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", dto.id)
        
        let bookEntity: BookEntity
        
        if let existingBook = try context.fetch(fetchRequest).first {
            bookEntity = existingBook
        } else {
            bookEntity = BookEntity(context: context)
            bookEntity.id = dto.id
        }
        
        // Kitap verilerini doldur
        bookEntity.title = dto.title
        bookEntity.subtitle = dto.subtitle
        bookEntity.authors = dto.authors.joined(separator: ",")
        bookEntity.isbn = dto.isbn
        bookEntity.publisher = dto.publisher
        bookEntity.publishedDate = dto.publishedDate
        bookEntity.bookDescription = dto.bookDescription
        bookEntity.language = dto.language
        bookEntity.categories = dto.categories.joined(separator: ",")
        bookEntity.smallThumbnailUrl = dto.smallThumbnailUrl
        bookEntity.thumbnailUrl = dto.thumbnailUrl
        bookEntity.pageCount = Int32(dto.pageCount ?? 0)
        bookEntity.dateAdded = dto.dateAdded
        bookEntity.startedAt = dto.startedAt
        bookEntity.completedAt = dto.completedAt
        bookEntity.lastReadAt = dto.lastReadAt
        bookEntity.currentPage = Int32(dto.currentPage)
        bookEntity.readingStatus = dto.readingStatus
        bookEntity.isFavorite = dto.isFavorite
        bookEntity.userRating = dto.userRating
        bookEntity.userNotes = dto.userNotes
        bookEntity.isSharedWithPartner = dto.isSharedWithPartner
        bookEntity.recommendedBy = dto.recommendedBy
        bookEntity.recommendedDate = dto.recommendedDate
        bookEntity.partnerNotes = dto.partnerNotes
        bookEntity.sharedCollectionIds = dto.sharedCollectionIds.joined(separator: ",")
        bookEntity.progressData = dto.progressData
        bookEntity.notesData = dto.notesData
        bookEntity.highlightsData = dto.highlightsData
        bookEntity.bookmarksData = dto.bookmarksData
        bookEntity.readingSessionsData = dto.readingSessionsData
        bookEntity.readingTime = Int32(dto.readingTime ?? 0)
        bookEntity.lastReadingSessionDate = dto.lastReadingSessionDate
    }
    
    private func restoreCollection(_ dto: BookCollectionDTO, context: NSManagedObjectContext) throws {
        let fetchRequest: NSFetchRequest<BookCollectionEntity> = BookCollectionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", dto.id)
        
        let collectionEntity: BookCollectionEntity
        
        if let existingCollection = try context.fetch(fetchRequest).first {
            collectionEntity = existingCollection
        } else {
            collectionEntity = BookCollectionEntity(context: context)
            collectionEntity.id = dto.id
        }
        
        // Koleksiyon verilerini doldur
        collectionEntity.name = dto.name
        collectionEntity.collectionDescription = dto.collectionDescription
        collectionEntity.bookIds = dto.bookIds.joined(separator: ",")
        collectionEntity.coverUrls = dto.coverUrls.joined(separator: ",")
        collectionEntity.createdDate = dto.createdDate
        collectionEntity.lastModifiedDate = dto.lastModifiedDate
        collectionEntity.isDefault = dto.isDefault
        collectionEntity.isSharedWithPartner = dto.isSharedWithPartner
        collectionEntity.ownerId = dto.ownerId
        collectionEntity.ownerUsername = dto.ownerUsername
        collectionEntity.sortOptionData = dto.sortOptionData
        collectionEntity.filterOptionsData = dto.filterOptionsData
    }
    
    private func restoreActivity(_ dto: ReadingActivityDTO, context: NSManagedObjectContext) throws {
        let fetchRequest: NSFetchRequest<ReadingActivityEntity> = ReadingActivityEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", dto.id)
        
        let activityEntity: ReadingActivityEntity
        
        if let existingActivity = try context.fetch(fetchRequest).first {
            activityEntity = existingActivity
        } else {
            activityEntity = ReadingActivityEntity(context: context)
            activityEntity.id = dto.id
        }
        
        // Aktivite verilerini doldur
        activityEntity.userId = dto.userId
        activityEntity.username = dto.username
        activityEntity.bookId = dto.bookId
        activityEntity.bookTitle = dto.bookTitle
        activityEntity.coverImageUrl = dto.coverImageUrl
        activityEntity.activityType = dto.activityType
        activityEntity.description = dto.description
        activityEntity.timestamp = dto.timestamp
    }
    
    private func restorePartnership(_ dto: PartnershipDTO, context: NSManagedObjectContext) throws {
        let fetchRequest: NSFetchRequest<PartnershipEntity> = PartnershipEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", dto.id)
        
        let partnershipEntity: PartnershipEntity
        
        if let existingPartnership = try context.fetch(fetchRequest).first {
            partnershipEntity = existingPartnership
        } else {
            partnershipEntity = PartnershipEntity(context: context)
            partnershipEntity.id = dto.id
        }
        
        // Ortaklık verilerini doldur
        partnershipEntity.userId = dto.userId
        partnershipEntity.partnerId = dto.partnerId
        partnershipEntity.partnerUsername = dto.partnerUsername
        partnershipEntity.status = dto.status
        partnershipEntity.createdAt = dto.createdAt
        partnershipEntity.updatedAt = dto.updatedAt
        partnershipEntity.lastActivityAt = dto.lastActivityAt
        partnershipEntity.sharedBookIds = dto.sharedBookIds.joined(separator: ",")
        partnershipEntity.activityNotificationsData = dto.activityNotificationsData
    }
}

// MARK: - DTO Models for Backup/Restore

/// Yedekleme için kullanıcı verilerini taşıyan ana model
struct UserBackupData: Codable {
    let user: UserDTO
    let books: [BookDTO]
    let collections: [BookCollectionDTO]
    let activities: [ReadingActivityDTO]
    let partnerships: [PartnershipDTO]
}

/// Kullanıcı verileri DTO
struct UserDTO: Codable {
    let id: String
    let username: String
    let email: String
    let profileImageUrl: String?
    let bio: String?
    let joinDate: Date
    let lastActive: Date
    let favoriteGenres: [String]
    let partnerId: String?
    let partnerUsername: String?
    let partnerProfileImageUrl: String?
    let isPartnershipActive: Bool
    let notificationsEnabled: Bool
    let themePreference: String
    let preferencesData: Data?
    let privacySettingsData: Data?
    let statisticsData: Data?
    let readingGoalData: Data?
}

/// Kitap verileri DTO
struct BookDTO: Codable {
    let id: String
    let title: String
    let subtitle: String?
    let authors: [String]
    let isbn: String?
    let publisher: String?
    let publishedDate: Date?
    let bookDescription: String?
    let language: String?
    let categories: [String]
    let smallThumbnailUrl: String?
    let thumbnailUrl: String?
    let pageCount: Int?
    let dateAdded: Date
    let startedAt: Date?
    let completedAt: Date?
    let lastReadAt: Date?
    let currentPage: Int
    let readingStatus: String
    let isFavorite: Bool
    let userRating: Float
    let userNotes: String?
    let isSharedWithPartner: Bool
    let recommendedBy: String?
    let recommendedDate: Date?
    let partnerNotes: String?
    let sharedCollectionIds: [String]
    let progressData: Data?
    let notesData: Data?
    let highlightsData: Data?
    let bookmarksData: Data?
    let readingSessionsData: Data?
    let readingTime: Int?
    let lastReadingSessionDate: Date?
}

/// Koleksiyon verileri DTO
struct BookCollectionDTO: Codable {
    let id: String
    let name: String
    let collectionDescription: String?
    let bookIds: [String]
    let coverUrls: [String]
    let createdDate: Date
    let lastModifiedDate: Date
    let isDefault: Bool
    let isSharedWithPartner: Bool
    let ownerId: String
    let ownerUsername: String
    let sortOptionData: Data?
    let filterOptionsData: Data?
}

/// Okuma aktivitesi verileri DTO
struct ReadingActivityDTO: Codable {
    let id: String
    let userId: String
    let username: String
    let bookId: String
    let bookTitle: String
    let coverImageUrl: String?
    let activityType: String
    let description: String
    let timestamp: Date
}

/// Ortaklık verileri DTO
struct PartnershipDTO: Codable {
    let id: String
    let userId: String
    let partnerId: String
    let partnerUsername: String
    let status: String
    let createdAt: Date
    let updatedAt: Date
    let lastActivityAt: Date?
    let sharedBookIds: [String]
    let activityNotificationsData: Data?
}

// MARK: - Errors

enum BackupError: Error {
    case userNotFound
    case fileCreationError
    case fileReadError
    case deserializationError
    case restoreError
}

extension BackupError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return NSLocalizedString("Kullanıcı bulunamadı.", comment: "")
        case .fileCreationError:
            return NSLocalizedString("Yedekleme dosyası oluşturulamadı.", comment: "")
        case .fileReadError:
            return NSLocalizedString("Yedekleme dosyası okunamadı.", comment: "")
        case .deserializationError:
            return NSLocalizedString("Yedekleme verileri işlenemedi.", comment: "")
        case .restoreError:
            return NSLocalizedString("Yedekleme geri yüklenirken hata oluştu.", comment: "")
        }
    }
} 