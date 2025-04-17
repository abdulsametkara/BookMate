import Foundation

/// Kitaplık görünüm modları
enum LibraryViewMode: Int, Codable, CaseIterable {
    /// Liste görünümü - kitaplar liste halinde gösterilir
    case list
    
    /// Grid görünümü - kitaplar ızgara şeklinde gösterilir
    case grid
    
    /// 3D Raf görünümü - kitaplar 3D kitaplık rafında gösterilir
    case shelf3D
    
    /// Varsayılan görünüm modu
    static var `default`: LibraryViewMode {
        return .grid
    }
    
    /// Kullanıcı arayüzünde görüntülenecek başlık
    var displayTitle: String {
        switch self {
        case .list:
            return "Liste"
        case .grid:
            return "Izgara"
        case .shelf3D:
            return "3D Raf"
        }
    }
    
    /// Görünüm modunu simgeleyen SF Symbol adı
    var iconName: String {
        switch self {
        case .list:
            return "list.bullet"
        case .grid:
            return "square.grid.2x2"
        case .shelf3D:
            return "books.vertical"
        }
    }
} 