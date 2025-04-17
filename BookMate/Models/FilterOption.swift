import Foundation

/// Kitapları filtreleme seçenekleri
enum FilterOption: Int, Codable, CaseIterable {
    /// Tüm kitaplar
    case all
    
    /// Sadece okunmamış kitaplar
    case unread
    
    /// Sadece devam etmekte olan kitaplar
    case inProgress
    
    /// Sadece tamamlanmış kitaplar
    case completed
    
    /// Favorilere eklenmiş kitaplar
    case favorites
    
    /// Paylaşılan kitaplar
    case shared
    
    /// Varsayılan filtreleme seçeneği
    static var `default`: FilterOption {
        return .all
    }
    
    /// Filtreleme seçeneğinin başlığı
    var displayTitle: String {
        switch self {
        case .all:
            return "Tümü"
        case .unread:
            return "Okunmamış"
        case .inProgress:
            return "Devam Ediyor"
        case .completed:
            return "Tamamlanmış"
        case .favorites:
            return "Favoriler"
        case .shared:
            return "Paylaşılanlar"
        }
    }
    
    /// Filtrelemeyi simgeleyen SF Symbol adı
    var iconName: String {
        switch self {
        case .all:
            return "books.vertical"
        case .unread:
            return "book.closed"
        case .inProgress:
            return "book"
        case .completed:
            return "checkmark.circle"
        case .favorites:
            return "heart.fill"
        case .shared:
            return "person.2"
        }
    }
} 