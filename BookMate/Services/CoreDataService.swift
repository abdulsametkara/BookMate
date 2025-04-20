import Foundation
import CoreData

class CoreDataService {
    // Singleton instance
    static let shared = CoreDataService()
    
    // Core Data container ve context
    private let persistentContainer: NSPersistentContainer
    private var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private init() {
        // Core Data container'ı oluşturma
        persistentContainer = NSPersistentContainer(name: "BookMate")
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data yüklenirken hata oluştu: \(error)")
            }
        }
    }
    
    // MARK: - Book Operations
    
    func fetchBooks() -> [BookEntity] {
        let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Kitaplar getirilirken hata oluştu: \(error)")
            return []
        }
    }
    
    func saveBook(book: Book) -> BookEntity? {
        let bookEntity = BookEntity(context: viewContext)
        bookEntity.id = book.id
        bookEntity.title = book.title
        bookEntity.author = book.author
        bookEntity.coverURL = book.coverURL
        bookEntity.isbn = book.isbn
        bookEntity.pageCount = Int16(book.pageCount)
        bookEntity.currentPage = Int16(book.currentPage)
        bookEntity.dateAdded = book.dateAdded
        bookEntity.dateFinished = book.dateFinished
        bookEntity.genre = book.genre
        bookEntity.notes = book.notes
        bookEntity.isFavorite = book.isFavorite
        if let rating = book.rating {
            bookEntity.rating = Int16(rating)
        }
        
        saveContext()
        return bookEntity
    }
    
    func updateBook(bookEntity: BookEntity, with book: Book) {
        bookEntity.title = book.title
        bookEntity.author = book.author
        bookEntity.coverURL = book.coverURL
        bookEntity.isbn = book.isbn
        bookEntity.pageCount = Int16(book.pageCount)
        bookEntity.currentPage = Int16(book.currentPage)
        bookEntity.dateFinished = book.dateFinished
        bookEntity.genre = book.genre
        bookEntity.notes = book.notes
        bookEntity.isFavorite = book.isFavorite
        if let rating = book.rating {
            bookEntity.rating = Int16(rating)
        }
        
        saveContext()
    }
    
    func deleteBook(bookEntity: BookEntity) {
        viewContext.delete(bookEntity)
        saveContext()
    }
    
    func getBookById(id: String) -> BookEntity? {
        let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            return results.first
        } catch {
            print("Kitap getirilirken hata oluştu: \(error)")
            return nil
        }
    }
    
    // Book Entity'den Book modeli oluşturma
    func convertToBook(from bookEntity: BookEntity) -> Book {
        return Book(
            id: bookEntity.id ?? UUID().uuidString,
            title: bookEntity.title ?? "",
            author: bookEntity.author ?? "",
            coverURL: bookEntity.coverURL,
            isbn: bookEntity.isbn,
            pageCount: Int(bookEntity.pageCount),
            currentPage: Int(bookEntity.currentPage),
            dateAdded: bookEntity.dateAdded ?? Date(),
            dateFinished: bookEntity.dateFinished,
            genre: bookEntity.genre,
            notes: bookEntity.notes,
            isFavorite: bookEntity.isFavorite,
            rating: bookEntity.rating > 0 ? Int(bookEntity.rating) : nil
        )
    }
    
    // MARK: - User Operations
    
    func saveUser(user: User) -> UserEntity? {
        // Önce mevcut bir kullanıcı var mı diye kontrol et
        if let existingUser = getUserById(id: user.id) {
            updateUser(userEntity: existingUser, with: user)
            return existingUser
        }
        
        // Yeni kullanıcı oluştur
        let userEntity = UserEntity(context: viewContext)
        userEntity.id = user.id
        userEntity.name = user.name
        userEntity.email = user.email
        userEntity.profileImageURL = user.profileImageURL
        userEntity.partnerId = user.partnerId
        userEntity.partnerName = user.partnerName
        userEntity.dateJoined = user.dateJoined
        
        // Okuma istatistiklerini kaydet
        let statsEntity = ReadingStatsEntity(context: viewContext)
        statsEntity.totalBooksRead = Int16(user.readingStats.totalBooksRead)
        statsEntity.totalPagesRead = Int32(user.readingStats.totalPagesRead)
        statsEntity.currentStreak = Int16(user.readingStats.currentStreak)
        statsEntity.longestStreak = Int16(user.readingStats.longestStreak)
        statsEntity.readingGoal = Int16(user.readingStats.readingGoal)
        statsEntity.weeklyReadingTime = Int32(user.readingStats.weeklyReadingTime)
        statsEntity.lastReadDate = user.readingStats.lastReadDate
        
        userEntity.readingStats = statsEntity
        
        // Kullanıcı tercihlerini kaydet
        let prefsEntity = UserPreferencesEntity(context: viewContext)
        prefsEntity.isDarkModeEnabled = user.preferences.isDarkModeEnabled
        prefsEntity.notificationsEnabled = user.preferences.notificationsEnabled
        prefsEntity.dailyReminderTime = user.preferences.dailyReminderTime
        prefsEntity.shareReadingStatus = user.preferences.shareReadingStatus
        prefsEntity.customThemeColor = user.preferences.customThemeColor
        
        userEntity.preferences = prefsEntity
        
        saveContext()
        return userEntity
    }
    
    func updateUser(userEntity: UserEntity, with user: User) {
        userEntity.name = user.name
        userEntity.email = user.email
        userEntity.profileImageURL = user.profileImageURL
        userEntity.partnerId = user.partnerId
        userEntity.partnerName = user.partnerName
        
        // Okuma istatistiklerini güncelle
        if let statsEntity = userEntity.readingStats {
            statsEntity.totalBooksRead = Int16(user.readingStats.totalBooksRead)
            statsEntity.totalPagesRead = Int32(user.readingStats.totalPagesRead)
            statsEntity.currentStreak = Int16(user.readingStats.currentStreak)
            statsEntity.longestStreak = Int16(user.readingStats.longestStreak)
            statsEntity.readingGoal = Int16(user.readingStats.readingGoal)
            statsEntity.weeklyReadingTime = Int32(user.readingStats.weeklyReadingTime)
            statsEntity.lastReadDate = user.readingStats.lastReadDate
        }
        
        // Kullanıcı tercihlerini güncelle
        if let prefsEntity = userEntity.preferences {
            prefsEntity.isDarkModeEnabled = user.preferences.isDarkModeEnabled
            prefsEntity.notificationsEnabled = user.preferences.notificationsEnabled
            prefsEntity.dailyReminderTime = user.preferences.dailyReminderTime
            prefsEntity.shareReadingStatus = user.preferences.shareReadingStatus
            prefsEntity.customThemeColor = user.preferences.customThemeColor
        }
        
        saveContext()
    }
    
    func getUserById(id: String) -> UserEntity? {
        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            return results.first
        } catch {
            print("Kullanıcı getirilirken hata oluştu: \(error)")
            return nil
        }
    }
    
    func convertToUser(from userEntity: UserEntity) -> User {
        var user = User(
            id: userEntity.id ?? UUID().uuidString,
            name: userEntity.name ?? "",
            email: userEntity.email ?? ""
        )
        
        // Diğer özellikleri ayarla
        user.profileImageURL = userEntity.profileImageURL
        user.partnerId = userEntity.partnerId
        user.partnerName = userEntity.partnerName
        user.dateJoined = userEntity.dateJoined ?? Date()
        
        // Okuma istatistiklerini ayarla
        if let statsEntity = userEntity.readingStats {
            var stats = ReadingStats()
            stats.totalBooksRead = Int(statsEntity.totalBooksRead)
            stats.totalPagesRead = Int(statsEntity.totalPagesRead)
            stats.currentStreak = Int(statsEntity.currentStreak)
            stats.longestStreak = Int(statsEntity.longestStreak)
            stats.readingGoal = Int(statsEntity.readingGoal)
            stats.weeklyReadingTime = Int(statsEntity.weeklyReadingTime)
            stats.lastReadDate = statsEntity.lastReadDate
            
            user.readingStats = stats
        }
        
        // Kullanıcı tercihlerini ayarla
        if let prefsEntity = userEntity.preferences {
            var prefs = UserPreferences()
            prefs.isDarkModeEnabled = prefsEntity.isDarkModeEnabled
            prefs.notificationsEnabled = prefsEntity.notificationsEnabled
            prefs.dailyReminderTime = prefsEntity.dailyReminderTime
            prefs.shareReadingStatus = prefsEntity.shareReadingStatus
            prefs.customThemeColor = prefsEntity.customThemeColor
            
            user.preferences = prefs
        }
        
        return user
    }
    
    // MARK: - Utils
    
    func saveContext() {
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Core Data kaydedilirken hata oluştu: \(nsError), \(nsError.userInfo)")
            }
        }
    }
} 