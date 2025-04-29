import Foundation
import UserNotifications
import UIKit

class NotificationService {
    static let shared = NotificationService()
    
    private let userNotificationCenter = UNUserNotificationCenter.current()
    private var isPermissionGranted = false
    
    private init() {
        checkNotificationPermission()
    }
    
    // Bildirim izinlerini kontrol et
    func checkNotificationPermission() {
        userNotificationCenter.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                self.isPermissionGranted = true
            default:
                self.isPermissionGranted = false
            }
        }
    }
    
    // Bildirim izni iste
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        userNotificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            self.isPermissionGranted = granted
            PushNotificationHelper.setNotificationPermissionRequested()
            
            if let error = error {
                print("Bildirim izni alınamadı: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                completion(granted)
                
                // İzin verildiyse, uygulama bildirim alması için kaydet
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    // Yerel bildirim göster
    func showLocalNotification(title: String, body: String, userInfo: [AnyHashable: Any]? = nil) {
        guard isPermissionGranted else {
            print("Bildirim izni yok")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        if let userInfo = userInfo {
            content.userInfo = userInfo
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        userNotificationCenter.add(request) { error in
            if let error = error {
                print("Bildirim gönderilemedi: \(error.localizedDescription)")
            }
        }
    }
    
    // Zamanlayıcı ile bildirim gönder (belli bir süre sonra)
    func scheduleLocalNotification(title: String, body: String, timeInterval: TimeInterval, userInfo: [AnyHashable: Any]? = nil) {
        guard isPermissionGranted else {
            print("Bildirim izni yok")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        if let userInfo = userInfo {
            content.userInfo = userInfo
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        userNotificationCenter.add(request) { error in
            if let error = error {
                print("Zamanlı bildirim ayarlanamadı: \(error.localizedDescription)")
            }
        }
    }
    
    // Günlük bildirim zamanla
    func scheduleDailyReminder(title: String, body: String, hour: Int, minute: Int) {
        guard isPermissionGranted else {
            print("Bildirim izni yok")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        
        // Önce mevcut günlük hatırlatıcıyı kaldır
        userNotificationCenter.removePendingNotificationRequests(withIdentifiers: ["dailyReminder"])
        
        userNotificationCenter.add(request) { error in
            if let error = error {
                print("Günlük hatırlatıcı ayarlanamadı: \(error.localizedDescription)")
            }
        }
    }
    
    // Tüm bekleyen bildirimleri iptal et
    func cancelAllPendingNotifications() {
        userNotificationCenter.removeAllPendingNotificationRequests()
    }
    
    // Tüm iletilen bildirimleri temizle
    func clearAllDeliveredNotifications() {
        userNotificationCenter.removeAllDeliveredNotifications()
    }
    
    // Belirli bir bildirimi iptal et
    func cancelNotification(withIdentifier identifier: String) {
        userNotificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    // APNs token'ı kaydet (Remote notifications için)
    func saveDeviceToken(_ deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(tokenString, forKey: "apnsToken")
        
        // Bu noktada token'ı kendi backend'inize de gönderebilirsiniz
        print("APNs token kaydedildi: \(tokenString)")
    }
    
    // Eşleşme bildirimi gönder
    func sendPartnerMatchNotification(partnerName: String) {
        showLocalNotification(
            title: "Eşleşme Tamamlandı",
            body: "\(partnerName) ile artık partnersiniz! Okuma deneyiminizi birlikte paylaşabilirsiniz."
        )
    }
    
    // Okuma etkinliği bildirimi gönder
    func sendReadingActivityNotification(partnerName: String, bookTitle: String, activity: String) {
        showLocalNotification(
            title: "Partner Aktivitesi",
            body: "\(partnerName) \(bookTitle) kitabını \(activity)."
        )
    }
    
    // Eşleşme isteği bildirimi gönder
    func sendPartnerRequestNotification(senderName: String) {
        showLocalNotification(
            title: "Eşleşme İsteği",
            body: "\(senderName) sizinle eşleşmek istiyor. Profil sayfanızdan istekleri görüntüleyebilirsiniz."
        )
    }
}