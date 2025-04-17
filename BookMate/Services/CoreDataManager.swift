import Foundation
import CoreData
import Combine

class CoreDataManager: DataManagerProtocol {
    static let shared = CoreDataManager()
    
    private init() {}
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "BookMate")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Core Data store hatası: \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Core Data Utility Methods
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("Kayıt hatası: \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - DataManagerProtocol Implementation
    
    // MARK: - Book Methods
    
    func fetchBooks() -> AnyPublisher<[Book], Error> {
        return Future<[Book], Error> { promise in
            let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
            
            do {
                let bookEntities = try self.viewContext.fetch(fetchRequest)
                let books = bookEntities.map { entity -> Book in
                    self.mapBookEntityToBook(entity)
                }
                promise(.success(books))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func fetchBook(id: String) -> AnyPublisher<Book, Error> {
        return Future<Book, Error> { promise in
            let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            
            do {
                let results = try self.viewContext.fetch(fetchRequest)
                if let bookEntity = results.first {
                    let book = self.mapBookEntityToBook(bookEntity)
                    promise(.success(book))
                } else {
                    promise(.failure(BookServiceError.notFound))
                }
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func fetchPartnerSharedBooks() -> AnyPublisher<[Book], Error> {
        return Future<[Book], Error> { promise in
            let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "isSharedWithPartner == %@", NSNumber(value: true))
            
            do {
                let bookEntities = try self.viewContext.fetch(fetchRequest)
                let books = bookEntities.map { entity -> Book in
                    self.mapBookEntityToBook(entity)
                }
                promise(.success(books))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func saveBook(_ book: Book) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            let context = self.viewContext
            
            // Mevcut kitabı bul veya yeni oluştur
            let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", book.id)
            
            do {
                let results = try context.fetch(fetchRequest)
                let bookEntity: BookEntity
                
                if let existingBook = results.first {
                    bookEntity = existingBook
                } else {
                    bookEntity = BookEntity(context: context)
                    bookEntity.id = book.id
                    bookEntity.dateAdded = book.dateAdded
                }
                
                // Özellikleri güncelle
                self.updateBookEntity(bookEntity, with: book)
                
                self.saveContext()
                promise(.success(true))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func deleteBook(id: String) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            
            do {
                let results = try self.viewContext.fetch(fetchRequest)
                if let bookToDelete = results.first {
                    self.viewContext.delete(bookToDelete)
                    self.saveContext()
                    promise(.success(true))
                } else {
                    promise(.success(false))
                }
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func updateReadingProgress(bookId: String, progress: ReadingProgress) -> AnyPublisher<Book, Error> {
        return Future<Book, Error> { promise in
            let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", bookId)
            
            do {
                let results = try self.viewContext.fetch(fetchRequest)
                if let bookEntity = results.first {
                    // Serileştir ve kaydet
                    bookEntity.progressData = try JSONEncoder().encode(progress)
                    
                    // Temel özellikler
                    bookEntity.currentPage = Int32(progress.currentPage)
                    bookEntity.readingStatus = progress.readingStatus.rawValue
                    bookEntity.lastReadAt = progress.lastReadAt
                    
                    if progress.readingStatus == .inProgress && bookEntity.startedAt == nil {
                        bookEntity.startedAt = Date()
                    } else if progress.readingStatus == .finished && bookEntity.completedAt == nil {
                        bookEntity.completedAt = Date()
                    }
                    
                    self.saveContext()
                    
                    let updatedBook = self.mapBookEntityToBook(bookEntity)
                    promise(.success(updatedBook))
                } else {
                    promise(.failure(BookServiceError.notFound))
                }
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func shareBookWithPartner(bookId: String, shared: Bool) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", bookId)
            
            do {
                let results = try self.viewContext.fetch(fetchRequest)
                if let bookEntity = results.first {
                    bookEntity.isSharedWithPartner = shared
                    self.saveContext()
                    promise(.success(true))
                } else {
                    promise(.failure(BookServiceError.notFound))
                }
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func searchBooks(query: String) -> AnyPublisher<[Book], Error> {
        return Future<[Book], Error> { promise in
            let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "title CONTAINS[cd] %@ OR authors CONTAINS[cd] %@", query, query)
            
            do {
                let bookEntities = try self.viewContext.fetch(fetchRequest)
                let books = bookEntities.map { entity -> Book in
                    self.mapBookEntityToBook(entity)
                }
                promise(.success(books))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func addNoteToBook(bookId: String, note: ReadingNote) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", bookId)
            
            do {
                let results = try self.viewContext.fetch(fetchRequest)
                if let bookEntity = results.first {
                    // Mevcut notları al veya yeni dizi oluştur
                    var notes: [ReadingNote] = []
                    if let notesData = bookEntity.notesData {
                        notes = try JSONDecoder().decode([ReadingNote].self, from: notesData)
                    }
                    
                    // Yeni notu ekle
                    notes.append(note)
                    
                    // Notları serileştir ve kaydet
                    bookEntity.notesData = try JSONEncoder().encode(notes)
                    
                    self.saveContext()
                    promise(.success(true))
                } else {
                    promise(.failure(BookServiceError.notFound))
                }
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func deleteNote(bookId: String, noteId: String) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", bookId)
            
            do {
                let results = try self.viewContext.fetch(fetchRequest)
                if let bookEntity = results.first, let notesData = bookEntity.notesData {
                    var notes = try JSONDecoder().decode([ReadingNote].self, from: notesData)
                    
                    // Notu bul ve sil
                    notes.removeAll { $0.id == noteId }
                    
                    // Güncellenmiş notları kaydet
                    bookEntity.notesData = try JSONEncoder().encode(notes)
                    
                    self.saveContext()
                    promise(.success(true))
                } else {
                    promise(.failure(BookServiceError.notFound))
                }
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    // MARK: - BookCollection Methods
    
    func fetchBookCollections(userId: String) -> AnyPublisher<[BookCollection], Error> {
        return Future<[BookCollection], Error> { promise in
            let fetchRequest: NSFetchRequest<BookCollectionEntity> = BookCollectionEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "ownerId == %@", userId)
            
            do {
                let collectionEntities = try self.viewContext.fetch(fetchRequest)
                let collections = try collectionEntities.map { entity -> BookCollection in
                    try self.mapCollectionEntityToBookCollection(entity)
                }
                promise(.success(collections))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func fetchPartnerSharedCollections() -> AnyPublisher<[BookCollection], Error> {
        return Future<[BookCollection], Error> { promise in
            // Önce mevcut kullanıcının partnerID'sini al
            guard let currentUserId = UserDefaults.standard.string(forKey: "currentUserId") else {
                promise(.failure(BookServiceError.authenticationError))
                return
            }
            
            // Kullanıcının partnerID'sini bul
            let userFetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
            userFetchRequest.predicate = NSPredicate(format: "id == %@", currentUserId)
            
            do {
                let userResults = try self.viewContext.fetch(userFetchRequest)
                guard let userEntity = userResults.first, let partnerId = userEntity.partnerId else {
                    promise(.success([]))
                    return
                }
                
                // Partner'ın paylaşılan koleksiyonlarını getir
                let fetchRequest: NSFetchRequest<BookCollectionEntity> = BookCollectionEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "ownerId == %@ AND isSharedWithPartner == %@", 
                                                   partnerId, NSNumber(value: true))
                
                let collectionEntities = try self.viewContext.fetch(fetchRequest)
                let collections = try collectionEntities.map { entity -> BookCollection in
                    try self.mapCollectionEntityToBookCollection(entity)
                }
                promise(.success(collections))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func fetchBookCollection(id: String) -> AnyPublisher<BookCollection, Error> {
        return Future<BookCollection, Error> { promise in
            let fetchRequest: NSFetchRequest<BookCollectionEntity> = BookCollectionEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            
            do {
                let results = try self.viewContext.fetch(fetchRequest)
                if let collectionEntity = results.first {
                    let collection = try self.mapCollectionEntityToBookCollection(collectionEntity)
                    promise(.success(collection))
                } else {
                    promise(.failure(BookServiceError.notFound))
                }
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func saveBookCollection(_ collection: BookCollection) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            let context = self.viewContext
            
            // Mevcut koleksiyonu bul veya yeni oluştur
            let fetchRequest: NSFetchRequest<BookCollectionEntity> = BookCollectionEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", collection.id)
            
            do {
                let results = try context.fetch(fetchRequest)
                let collectionEntity: BookCollectionEntity
                
                if let existingCollection = results.first {
                    collectionEntity = existingCollection
                } else {
                    collectionEntity = BookCollectionEntity(context: context)
                    collectionEntity.id = collection.id
                    collectionEntity.createdDate = collection.createdDate
                }
                
                // Özellikleri güncelle
                collectionEntity.name = collection.name
                collectionEntity.collectionDescription = collection.description
                collectionEntity.lastModifiedDate = collection.lastModifiedDate
                collectionEntity.isDefault = collection.isDefault
                collectionEntity.isSharedWithPartner = collection.isSharedWithPartner
                collectionEntity.ownerId = collection.ownerId
                collectionEntity.ownerUsername = collection.ownerUsername
                
                // Koleksiyon ayarlarını JSON olarak sakla
                collectionEntity.sortOptionData = try JSONEncoder().encode(collection.sortOption)
                collectionEntity.filterOptionsData = try JSONEncoder().encode(collection.filterOptions)
                
                // Kitap ID'lerini sakla
                collectionEntity.bookIds = collection.books.map { $0.id }.joined(separator: ",")
                
                // Kapak resim URL'lerini sakla
                if let coverUrls = collection.coverImages {
                    collectionEntity.coverUrls = coverUrls.map { $0.absoluteString }.joined(separator: ",")
                }
                
                self.saveContext()
                promise(.success(true))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    func deleteBookCollection(id: String) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            let fetchRequest: NSFetchRequest<BookCollectionEntity> = BookCollectionEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
            
            do {
                let results = try self.viewContext.fetch(fetchRequest)
                if let collectionToDelete = results.first {
                    self.viewContext.delete(collectionToDelete)
                    self.saveContext()
                    promise(.success(true))
                } else {
                    promise(.success(false))
                }
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    // MARK: - Reading Activity Methods
    
    func saveReadingActivity(_ activity: ReadingActivity) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { promise in
            let activityEntity = ReadingActivityEntity(context: self.viewContext)
            activityEntity.id = activity.id
            activityEntity.userId = activity.userId
            activityEntity.username = activity.username
            activityEntity.bookId = activity.bookId
            activityEntity.bookTitle = activity.bookTitle
            activityEntity.activityType = activity.activityType.rawValue
            activityEntity.description = activity.description
            activityEntity.timestamp = activity.timestamp
            
            if let coverUrl = activity.coverImageUrl {
                activityEntity.coverImageUrl = coverUrl.absoluteString
            }
            
            self.saveContext()
            promise(.success(true))
        }.eraseToAnyPublisher()
    }
    
    // MARK: - Helper Methods
    
    private func mapBookEntityToBook(_ bookEntity: BookEntity) -> Book {
        // Deserialize complex objects
        var readingProgress: ReadingProgress?
        var notes: [ReadingNote] = []
        var highlights: [HighlightedPassage] = []
        var bookmarks: [Bookmark] = []
        var readingSessions: [ReadingSession] = []
        
        if let progressData = bookEntity.progressData {
            do {
                readingProgress = try JSONDecoder().decode(ReadingProgress.self, from: progressData)
            } catch {
                print("Reading progress deserialization error: \(error)")
            }
        }
        
        if let notesData = bookEntity.notesData {
            do {
                notes = try JSONDecoder().decode([ReadingNote].self, from: notesData)
            } catch {
                print("Notes deserialization error: \(error)")
            }
        }
        
        if let highlightsData = bookEntity.highlightsData {
            do {
                highlights = try JSONDecoder().decode([HighlightedPassage].self, from: highlightsData)
            } catch {
                print("Highlights deserialization error: \(error)")
            }
        }
        
        if let bookmarksData = bookEntity.bookmarksData {
            do {
                bookmarks = try JSONDecoder().decode([Bookmark].self, from: bookmarksData)
            } catch {
                print("Bookmarks deserialization error: \(error)")
            }
        }
        
        if let sessionsData = bookEntity.readingSessionsData {
            do {
                readingSessions = try JSONDecoder().decode([ReadingSession].self, from: sessionsData)
            } catch {
                print("Reading sessions deserialization error: \(error)")
            }
        }
        
        // Parse categories
        var categories: [String]?
        if let categoriesString = bookEntity.categories, !categoriesString.isEmpty {
            categories = categoriesString.components(separatedBy: ",")
        }
        
        // Parse authors
        var authors: [String]?
        if let authorsString = bookEntity.authors, !authorsString.isEmpty {
            authors = authorsString.components(separatedBy: ",")
        }
        
        // Parse collection IDs
        var sharedCollectionIds: [String]?
        if let collectionsString = bookEntity.sharedCollectionIds, !collectionsString.isEmpty {
            sharedCollectionIds = collectionsString.components(separatedBy: ",")
        }
        
        // Create image links
        var imageLinks: BookImageLinks?
        if let smallThumbnailString = bookEntity.smallThumbnailUrl, 
           let thumbnailString = bookEntity.thumbnailUrl {
            let smallThumbnail = URL(string: smallThumbnailString)
            let thumbnail = URL(string: thumbnailString)
            imageLinks = BookImageLinks(smallThumbnail: smallThumbnail, thumbnail: thumbnail)
        }
        
        return Book(
            id: bookEntity.id ?? UUID().uuidString,
            isbn: bookEntity.isbn,
            title: bookEntity.title ?? "",
            subtitle: bookEntity.subtitle,
            authors: authors,
            publisher: bookEntity.publisher,
            publishedDate: bookEntity.publishedDate,
            description: bookEntity.bookDescription,
            pageCount: Int(bookEntity.pageCount),
            categories: categories,
            imageLinks: imageLinks,
            language: bookEntity.language,
            dateAdded: bookEntity.dateAdded ?? Date(),
            startedReading: bookEntity.startedAt,
            finishedReading: bookEntity.completedAt,
            currentPage: Int(bookEntity.currentPage),
            readingStatus: ReadingStatus(rawValue: bookEntity.readingStatus ?? "") ?? .notStarted,
            isFavorite: bookEntity.isFavorite,
            userRating: bookEntity.userRating > 0 ? Double(bookEntity.userRating) : nil,
            userNotes: bookEntity.userNotes,
            highlightedPassages: highlights.isEmpty ? nil : highlights,
            bookmarks: bookmarks.isEmpty ? nil : bookmarks,
            readingTime: bookEntity.readingTime > 0 ? Double(bookEntity.readingTime) : nil,
            lastReadingSession: bookEntity.lastReadingSessionDate,
            readingSessions: readingSessions.isEmpty ? nil : readingSessions,
            recommendedBy: bookEntity.recommendedBy,
            recommendedDate: bookEntity.recommendedDate,
            sharedCollectionIds: sharedCollectionIds,
            partnerNotes: bookEntity.partnerNotes
        )
    }
    
    private func updateBookEntity(_ entity: BookEntity, with book: Book) {
        entity.title = book.title
        entity.subtitle = book.subtitle
        entity.isbn = book.isbn
        entity.publisher = book.publisher
        entity.publishedDate = book.publishedDate
        entity.bookDescription = book.description
        entity.pageCount = Int32(book.pageCount ?? 0)
        entity.language = book.language
        
        // Serileştir ve kaydet
        do {
            if let progress = book.userProgress {
                entity.progressData = try JSONEncoder().encode(progress)
                entity.currentPage = Int32(progress.currentPage)
                entity.readingStatus = progress.readingStatus.rawValue
            }
            
            if let notes = book.userNotes, !notes.isEmpty {
                entity.userNotes = notes
            }
            
            if let highlights = book.highlightedPassages {
                entity.highlightsData = try JSONEncoder().encode(highlights)
            }
            
            if let bookmarks = book.bookmarks {
                entity.bookmarksData = try JSONEncoder().encode(bookmarks)
            }
            
            if let sessions = book.readingSessions {
                entity.readingSessionsData = try JSONEncoder().encode(sessions)
            }
        } catch {
            print("Serialization error: \(error)")
        }
        
        // String dizileri için
        if let authors = book.authors {
            entity.authors = authors.joined(separator: ",")
        }
        
        if let categories = book.categories {
            entity.categories = categories.joined(separator: ",")
        }
        
        if let collections = book.sharedCollectionIds {
            entity.sharedCollectionIds = collections.joined(separator: ",")
        }
        
        // Image URLs
        if let imageLinks = book.imageLinks {
            entity.smallThumbnailUrl = imageLinks.smallThumbnail?.absoluteString
            entity.thumbnailUrl = imageLinks.thumbnail?.absoluteString
        }
        
        // Diğer özellikler
        entity.startedAt = book.startedReading
        entity.completedAt = book.finishedReading
        entity.lastReadAt = book.lastReadingSession
        entity.isFavorite = book.isFavorite
        entity.isSharedWithPartner = book.sharedCollectionIds != nil && !book.sharedCollectionIds!.isEmpty
        
        if let rating = book.userRating {
            entity.userRating = Float(rating)
        }
        
        if let time = book.readingTime {
            entity.readingTime = Int32(time)
        }
        
        entity.recommendedBy = book.recommendedBy
        entity.recommendedDate = book.recommendedDate
        entity.partnerNotes = book.partnerNotes
        entity.lastReadingSessionDate = book.lastReadingSession
    }
    
    private func mapCollectionEntityToBookCollection(_ entity: BookCollectionEntity) throws -> BookCollection {
        // Get book IDs
        var books: [Book] = []
        if let bookIdsString = entity.bookIds, !bookIdsString.isEmpty {
            let bookIds = bookIdsString.components(separatedBy: ",")
            
            // Fetch books by IDs
            let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id IN %@", bookIds)
            
            let bookEntities = try viewContext.fetch(fetchRequest)
            books = bookEntities.map { self.mapBookEntityToBook($0) }
        }
        
        // Get cover image URLs
        var coverImages: [URL]?
        if let coverUrlsString = entity.coverUrls, !coverUrlsString.isEmpty {
            let urlStrings = coverUrlsString.components(separatedBy: ",")
            coverImages = urlStrings.compactMap { URL(string: $0) }
        }
        
        // Deserialize sort option and filter options
        let sortOption: SortOption
        let filterOptions: [FilterOption]
        
        if let sortData = entity.sortOptionData {
            sortOption = try JSONDecoder().decode(SortOption.self, from: sortData)
        } else {
            sortOption = .title
        }
        
        if let filterData = entity.filterOptionsData {
            filterOptions = try JSONDecoder().decode([FilterOption].self, from: filterData)
        } else {
            filterOptions = []
        }
        
        return BookCollection(
            id: entity.id ?? UUID().uuidString,
            name: entity.name ?? "",
            description: entity.collectionDescription,
            books: books,
            coverImages: coverImages,
            createdDate: entity.createdDate ?? Date(),
            lastModifiedDate: entity.lastModifiedDate ?? Date(),
            isDefault: entity.isDefault,
            isSharedWithPartner: entity.isSharedWithPartner,
            sortOption: sortOption,
            filterOptions: filterOptions,
            ownerId: entity.ownerId ?? "",
            ownerUsername: entity.ownerUsername ?? ""
        )
    }
}

extension CoreDataManager {
    func setupDefaultCollectionsIfNeeded(userId: String, username: String) {
        // Check if the user already has collections
        let fetchRequest: NSFetchRequest<BookCollectionEntity> = BookCollectionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "ownerId == %@", userId)
        
        do {
            let count = try viewContext.count(for: fetchRequest)
            if count == 0 {
                // Create default collections
                let defaultCollections = BookCollection.createDefaultCollections(
                    ownerId: userId,
                    ownerUsername: username
                )
                
                for collection in defaultCollections {
                    _ = saveBookCollection(collection)
                }
            }
        } catch {
            print("Error checking for existing collections: \(error)")
        }
    }
} 