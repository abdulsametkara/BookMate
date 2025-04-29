import Foundation
import Combine
import UIKit

class NotificationViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let firebaseService = FirebaseService.shared
    private let notificationService = NotificationService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupNotificationTracking()
    }
    
    // Bildirim takibi için timer ve dinleyicileri kur
    private func setupNotificationTracking() {
        // Uygulama aktif olduğunda bildirimleri güncelle
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.loadNotifications()
            }
            .store(in: &cancellables)
        
        // Bildirim izinlerini kontrol et
        notificationService.checkNotificationPermission()
        
        // Her dakika bildirimleri yenile (veya Firebase listener da kullanılabilir)
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshUnreadCount()
            }
            .store(in: &cancellables)
    }
    
    // Bildirimleri yükle
    func loadNotifications() {
        guard let user = UserSession.shared.getCurrentUser() else { return }
        
        isLoading = true
        
        Task {
            do {
                let notifications = try await firebaseService.getNotifications(userId: user.id.uuidString)
                let unreadCount = try await firebaseService.getUnreadNotificationsCount(userId: user.id.uuidString)
                
                DispatchQueue.main.async {
                    self.notifications = notifications
                    self.unreadCount = unreadCount
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Bildirimler yüklenemedi: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    // Okunmamış bildirim sayısını güncelle
    func refreshUnreadCount() {
        guard let user = UserSession.shared.getCurrentUser() else { return }
        
        Task {
            do {
                let count = try await firebaseService.getUnreadNotificationsCount(userId: user.id.uuidString)
                
                DispatchQueue.main.async {
                    self.unreadCount = count
                }
            } catch {
                print("Okunmamış bildirim sayısı alınamadı: \(error.localizedDescription)")
            }
        }
    }
    
    // Bildirimi okundu olarak işaretle
    func markAsRead(notificationId: String) {
        guard let user = UserSession.shared.getCurrentUser() else { return }
        
        Task {
            do {
                try await firebaseService.markNotificationAsRead(userId: user.id.uuidString, notificationId: notificationId)
                
                DispatchQueue.main.async {
                    if let index = self.notifications.firstIndex(where: { $0.id == notificationId }) {
                        self.notifications[index].isRead = true
                    }
                    self.refreshUnreadCount()
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Bildirim okundu olarak işaretlenemedi: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // Tüm bildirimleri okundu olarak işaretle
    func markAllAsRead() {
        guard let user = UserSession.shared.getCurrentUser() else { return }
        
        Task {
            do {
                try await firebaseService.markAllNotificationsAsRead(userId: user.id.uuidString)
                
                DispatchQueue.main.async {
                    for i in 0..<self.notifications.count {
                        self.notifications[i].isRead = true
                    }
                    self.unreadCount = 0
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Bildirimler okundu olarak işaretlenemedi: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // Bildirimi sil (örnek uygulama için opsiyonel)
    func deleteNotification(notificationId: String) {
        // Bu işlev gerekirse eklenebilir
    }
    
    // Bildirim izni iste
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        notificationService.requestNotificationPermission { granted in
            completion(granted)
        }
    }
    
    // Yerel bildirim gönder
    func showLocalNotification(title: String, body: String) {
        notificationService.showLocalNotification(title: title, body: body)
    }
    
    // Bildirim eylemini gerçekleştir
    func handleNotificationAction(notification: AppNotification) {
        // Bildirim türüne göre uygun işlemi gerçekleştir
        markAsRead(notificationId: notification.id)
        
        switch notification.type {
        case .partnerRequest:
            // Partner isteği sayfasına yönlendir
            break
            
        case .partnerAccepted:
            // Partner profiline yönlendir
            break
            
        case .partnerActivity:
            // Aktivite detayına yönlendir
            break
            
        case .bookRecommendation:
            // Kitap detayına yönlendir
            break
            
        default:
            // Diğer bildirim türleri için özel işlem
            break
        }
    }
} 