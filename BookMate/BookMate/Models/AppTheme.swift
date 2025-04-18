import Foundation
import SwiftUI

enum AppTheme: String, Codable {
    case light
    case dark
    case system
    
    var description: String {
        switch self {
        case .light:
            return "Açık Tema"
        case .dark:
            return "Koyu Tema"
        case .system:
            return "Sistem Teması"
        }
    }
    
    var name: String {
        switch self {
        case .light:
            return "Açık"
        case .dark:
            return "Koyu"
        case .system:
            return "Sistem"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
} 