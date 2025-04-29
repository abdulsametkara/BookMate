import Foundation

// Uygulama içi bildirim modeli
struct AppNotification: Identifiable, Codable {
    var id: String
    var userId: String
    var title: String
    var message: String
    var type: NotificationType
    var timestamp: Date
    var isRead: Bool
    var data: NotificationData?
    var actionable: Bool // Kullanıcının bir eylem yapması gerekip gerekmediği
    
    enum NotificationType: String, Codable {
        case partnerRequest = "partnerRequest"
        case partnerAccepted = "partnerAccepted"
        case partnerRejected = "partnerRejected"
        case partnerActivity = "partnerActivity"
        case goalAchieved = "goalAchieved"
        case streakUpdate = "streakUpdate"
        case milestone = "milestone"
        case reminderToRead = "reminderToRead"
        case bookRecommendation = "bookRecommendation"
        case systemNotification = "systemNotification"
    }
    
    struct NotificationData: Codable {
        // Partner ile ilgili bildirimler için
        var partnerId: String?
        var partnerUsername: String?
        
        // Kitap ile ilgili bildirimler için
        var bookId: String?
        var bookTitle: String?
        var bookCoverURL: URL?
        
        // Hedef ile ilgili bildirimler için
        var goalType: ReadingGoalType?
        var progress: Double?
        var target: Int?
        
        // Streak ile ilgili bildirimler için
        var streakDays: Int?
        
        // Dönülecek sayfa
        var deepLink: String?
    }
}

// Bildirim tercihleri
struct NotificationPreferences: Codable {
    var partnerRequests: Bool = true
    var partnerActivities: Bool = true
    var goalUpdates: Bool = true
    var streakUpdates: Bool = true
    var milestones: Bool = true
    var dailyReminders: Bool = false
    var recommendations: Bool = true
    var systemUpdates: Bool = true
    
    // Bildirim zamanları
    var dailyReminderTime: Date? // Günlük hatırlatıcı zamanı
    var quietHoursStart: Date? // Rahatsız etmeme modu başlangıç
    var quietHoursEnd: Date? // Rahatsız etmeme modu bitiş
    
    // Bildirim sesleri
    var notificationSound: NotificationSound = .default
    
    enum NotificationSound: String, Codable, CaseIterable {
        case `default` = "default"
        case subtle = "subtle"
        case bookPage = "bookPage"
        case chime = "chime"
        case none = "none"
    }
}

// Push bildirim için yardımcı fonksiyonlar
struct PushNotificationHelper {
    // APNs token'ı UserDefaults'a kaydetme
    static func saveDeviceToken(_ tokenData: Data) {
        let tokenString = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(tokenString, forKey: "apnsToken")
    }
    
    // Kayıtlı token'ı alma
    static func getDeviceToken() -> String? {
        return UserDefaults.standard.string(forKey: "apnsToken")
    }
    
    // Bildirimlere izin istemek için kontrol
    static func shouldRequestNotificationPermission() -> Bool {
        // İlk kurulumda veya kullanıcı bildirimleri aktifleştirmek istediğinde true döner
        return !UserDefaults.standard.bool(forKey: "notificationPermissionRequested")
    }
    
    // Bildirim izni istendiğini kaydet
    static func setNotificationPermissionRequested() {
        UserDefaults.standard.set(true, forKey: "notificationPermissionRequested")
    }
    
    // Push bildirim formatı
    static func createPushPayload(title: String, body: String, data: [String: Any]? = nil) -> [String: Any] {
        var payload: [String: Any] = [
            "aps": [
                "alert": [
                    "title": title,
                    "body": body
                ],
                "sound": "default",
                "badge": 1
            ]
        ]
        
        if let data = data {
            payload["data"] = data
        }
        
        return payload
    }
} 