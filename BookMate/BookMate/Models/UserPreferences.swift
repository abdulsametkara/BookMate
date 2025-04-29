import Foundation

// Kullanıcı tercihleri
struct UserPreferences: Codable, Equatable {
    var notificationsEnabled: Bool
    var notificationPreferences: NotificationPreferences
    var privacySettings: PrivacySettings
    var darkModeEnabled: Bool
    var fontSizePreference: FontSize
    
    enum FontSize: String, Codable, CaseIterable {
        case small = "small"
        case medium = "medium"
        case large = "large"
        case extraLarge = "extraLarge"
    }
    
    static func defaultPreferences() -> UserPreferences {
        return UserPreferences(
            notificationsEnabled: true,
            notificationPreferences: NotificationPreferences(),
            privacySettings: PrivacySettings(),
            darkModeEnabled: false,
            fontSizePreference: .medium
        )
    }
    
    static func == (lhs: UserPreferences, rhs: UserPreferences) -> Bool {
        return lhs.notificationsEnabled == rhs.notificationsEnabled &&
               lhs.darkModeEnabled == rhs.darkModeEnabled &&
               lhs.fontSizePreference == rhs.fontSizePreference
    }
} 