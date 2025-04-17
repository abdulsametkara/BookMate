import Foundation

/// Kitapları sıralama seçenekleri
enum SortOption: Int, Codable, CaseIterable {
    /// Alfabetik sıralama (kitap adına göre)
    case title
    
    /// Yazara göre sıralama
    case author
    
    /// En son eklenen kitaplara göre sıralama
    case dateAdded
    
    /// En son okunan kitaplara göre sıralama
    case lastRead
    
    /// Derecelendirmeye göre sıralama (en yüksekten en düşüğe)
    case rating
    
    /// Okuma ilerlemesine göre sıralama (yüzde olarak)
    case progress
    
    /// Varsayılan sıralama seçeneği
    static var `default`: SortOption {
        return .dateAdded
    }
    
    /// Sıralama seçeneğinin başlığı
    var displayTitle: String {
        switch self {
        case .title:
            return "Kitap Adı"
        case .author:
            return "Yazar"
        case .dateAdded:
            return "Eklenme Tarihi"
        case .lastRead:
            return "Son Okuma"
        case .rating:
            return "Derecelendirme"
        case .progress:
            return "İlerleme"
        }
    }
    
    /// Sıralamayı simgeleyen SF Symbol adı
    var iconName: String {
        switch self {
        case .title:
            return "textformat"
        case .author:
            return "person"
        case .dateAdded:
            return "calendar"
        case .lastRead:
            return "clock"
        case .rating:
            return "star"
        case .progress:
            return "chart.bar.fill"
        }
    }
} 