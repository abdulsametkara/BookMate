import Foundation

struct User: Identifiable, Codable, Equatable {
    var id: String
    var username: String
    var email: String
    var profileImageUrl: URL?
    var bio: String?
    var joinDate: Date
    var lastActive: Date
    
    var favoriteGenres: [String]
    var readingGoal: BookMate.ReadingGoal?
    var statistics: BookMate.ReadingStatistics?
    
    var partnerId: String?
    var partnerUsername: String?
    var partnerProfileImageUrl: URL?
    var isPartnershipActive: Bool
    
    var appTheme: BookMate.AppTheme
    var notificationsEnabled: Bool
    var privacySettings: BookMate.PrivacySettings
    
    var hasPartner: Bool {
        return partnerId != nil && isPartnershipActive
    }
    
    // Computed properties for UI
    var displayName: String {
        return username
    }
    
    var profilePhotoURL: String? {
        return profileImageUrl?.absoluteString
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
} 