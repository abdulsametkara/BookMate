import Foundation
import SwiftUI

enum AppTheme: String, Codable, CaseIterable {
    case light
    case dark
    case system
    
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