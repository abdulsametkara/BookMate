import Foundation

struct PrivacySettings: Codable, Equatable {
    var shareReadingProgress: Bool
    var shareNotes: Bool
    var shareStats: Bool
    var shareActivity: Bool
    
    init(shareReadingProgress: Bool = true,
         shareNotes: Bool = true,
         shareStats: Bool = true,
         shareActivity: Bool = true) {
        
        self.shareReadingProgress = shareReadingProgress
        self.shareNotes = shareNotes
        self.shareStats = shareStats
        self.shareActivity = shareActivity
    }
    
    static var `default`: PrivacySettings {
        return PrivacySettings()
    }
} 