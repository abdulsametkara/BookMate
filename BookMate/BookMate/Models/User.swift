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
    var readingGoal: ReadingGoal?
    var statistics: ReadingStatistics?
    
    var partnerId: String?
    var partnerUsername: String?
    var partnerProfileImageUrl: URL?
    var isPartnershipActive: Bool
    
    var appTheme: AppTheme
    var notificationsEnabled: Bool
    var privacySettings: PrivacySettings
    
    var hasPartner: Bool {
        return partnerId != nil && isPartnershipActive
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
} 