import Foundation

struct PrivacySettings: Codable, Equatable {
    var shareReadingProgress: Bool
    var shareNotes: Bool
    var shareStats: Bool
    var shareActivity: Bool
    var isProfilePublic: Bool
    
    init(shareReadingProgress: Bool = true,
         shareNotes: Bool = true,
         shareStats: Bool = true,
         shareActivity: Bool = true,
         isProfilePublic: Bool = true) {
        
        self.shareReadingProgress = shareReadingProgress
        self.shareNotes = shareNotes
        self.shareStats = shareStats
        self.shareActivity = shareActivity
        self.isProfilePublic = isProfilePublic
    }
} 