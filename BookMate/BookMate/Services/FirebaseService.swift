import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

class FirebaseService {
    static let shared = FirebaseService()
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    private init() {
        // Firebase başlatma işlemi app delegate'de yapılmıştır
    }
    
    // MARK: - Kullanıcı İşlemleri
    
    func getCurrentUser() -> FirebaseAuth.User? {
        return auth.currentUser
    }
    
    func createUser(email: String, password: String, username: String) async throws -> String {
        // Kullanıcı oluştur
        let result = try await auth.createUser(withEmail: email, password: password)
        let userId = result.user.uid
        
        // Kullanıcı profili oluştur
        let userData: [String: Any] = [
            "username": username,
            "email": email,
            "createdAt": FieldValue.serverTimestamp(),
            "lastActive": FieldValue.serverTimestamp(),
        ]
        
        try await db.collection("users").document(userId).setData(userData)
        
        return userId
    }
    
    func signIn(email: String, password: String) async throws -> FirebaseAuth.User {
        let result = try await auth.signIn(withEmail: email, password: password)
        
        // Son aktif zamanı güncelle
        if let userId = result.user.uid as String? {
            try await db.collection("users").document(userId).updateData([
                "lastActive": FieldValue.serverTimestamp()
            ])
        }
        
        return result.user
    }
    
    func signOut() throws {
        try auth.signOut()
    }
    
    // MARK: - Partner İşlemleri
    
    // Partner kodu oluştur
    func generatePartnerCode(userId: String) async throws -> String {
        // 6 haneli benzersiz kod oluştur
        let code = String(format: "%06d", Int.random(in: 100000..<1000000))
        
        // Kodun benzersiz olup olmadığını kontrol et
        let query = try await db.collection("partnerCodes").whereField("code", isEqualTo: code).getDocuments()
        
        if !query.documents.isEmpty {
            // Kod zaten kullanılıyor, yeniden dene
            return try await generatePartnerCode(userId: userId)
        }
        
        // Kodu kaydet
        try await db.collection("partnerCodes").document(userId).setData([
            "code": code,
            "userId": userId,
            "createdAt": FieldValue.serverTimestamp(),
            "isActive": true
        ])
        
        return code
    }
    
    // Kod ile partner bul
    func findUserByPartnerCode(code: String) async throws -> String? {
        let query = try await db.collection("partnerCodes").whereField("code", isEqualTo: code).getDocuments()
        
        guard let document = query.documents.first, document.exists else {
            return nil
        }
        
        return document.data()["userId"] as? String
    }
    
    // Partner isteği gönder
    func sendPartnerRequest(fromUserId: String, toUserId: String) async throws {
        // İsteği oluştur
        let requestData: [String: Any] = [
            "fromUserId": fromUserId,
            "status": "pending",
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        // Gönderen hakkında bilgi al
        let senderDoc = try await db.collection("users").document(fromUserId).getDocument()
        
        guard let senderData = senderDoc.data(),
              let senderUsername = senderData["username"] as? String else {
            throw NSError(domain: "FirebaseService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Gönderen kullanıcı bilgileri alınamadı."
            ])
        }
        
        // İsteği alıcının koleksiyonuna ekle
        try await db.collection("users").document(toUserId).collection("partnerRequests").document(fromUserId).setData(requestData)
        
        // Bildirim oluştur
        let notificationId = UUID().uuidString
        let notificationData: [String: Any] = [
            "id": notificationId,
            "userId": toUserId,
            "title": "Eşleşme İsteği",
            "message": "\(senderUsername) sizinle eşleşmek istiyor.",
            "type": "partnerRequest",
            "data": [
                "partnerId": fromUserId,
                "partnerUsername": senderUsername
            ],
            "timestamp": FieldValue.serverTimestamp(),
            "isRead": false,
            "actionable": true
        ]
        
        try await db.collection("users").document(toUserId).collection("notifications").document(notificationId).setData(notificationData)
    }
    
    // Partner isteğini kabul et
    func acceptPartnerRequest(userId: String, partnerId: String) async throws {
        // İsteği güncelle
        try await db.collection("users").document(userId).collection("partnerRequests").document(partnerId).updateData([
            "status": "accepted",
            "acceptedAt": FieldValue.serverTimestamp()
        ])
        
        // Her iki kullanıcı için de partner ilişkisi oluştur
        let userDoc = try await db.collection("users").document(userId).getDocument()
        let partnerDoc = try await db.collection("users").document(partnerId).getDocument()
        
        guard let userData = userDoc.data(),
              let partnerData = partnerDoc.data(),
              let username = userData["username"] as? String,
              let partnerUsername = partnerData["username"] as? String else {
            throw NSError(domain: "FirebaseService", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Kullanıcı bilgileri alınamadı."
            ])
        }
        
        // Kullanıcı bilgilerini güncelle
        try await db.collection("users").document(userId).updateData([
            "partnerId": partnerId,
            "partnerUsername": partnerUsername,
            "isPartnershipActive": true,
            "partnerLastActivity": FieldValue.serverTimestamp()
        ])
        
        try await db.collection("users").document(partnerId).updateData([
            "partnerId": userId,
            "partnerUsername": username,
            "isPartnershipActive": true,
            "partnerLastActivity": FieldValue.serverTimestamp()
        ])
        
        // Her iki kullanıcıya da bildirim gönder
        // Kullanıcı için bildirim
        let userNotificationId = UUID().uuidString
        let userNotificationData: [String: Any] = [
            "id": userNotificationId,
            "userId": userId,
            "title": "Eşleşme Tamamlandı",
            "message": "\(partnerUsername) ile artık partnersiniz!",
            "type": "partnerAccepted",
            "data": [
                "partnerId": partnerId,
                "partnerUsername": partnerUsername
            ],
            "timestamp": FieldValue.serverTimestamp(),
            "isRead": false,
            "actionable": false
        ]
        
        // Partner için bildirim
        let partnerNotificationId = UUID().uuidString
        let partnerNotificationData: [String: Any] = [
            "id": partnerNotificationId,
            "userId": partnerId,
            "title": "Eşleşme Tamamlandı",
            "message": "\(username) eşleşme isteğinizi kabul etti!",
            "type": "partnerAccepted",
            "data": [
                "partnerId": userId,
                "partnerUsername": username
            ],
            "timestamp": FieldValue.serverTimestamp(),
            "isRead": false,
            "actionable": false
        ]
        
        try await db.collection("users").document(userId).collection("notifications").document(userNotificationId).setData(userNotificationData)
        try await db.collection("users").document(partnerId).collection("notifications").document(partnerNotificationId).setData(partnerNotificationData)
    }
    
    // Partner isteğini reddet
    func rejectPartnerRequest(userId: String, partnerId: String) async throws {
        try await db.collection("users").document(userId).collection("partnerRequests").document(partnerId).updateData([
            "status": "rejected",
            "rejectedAt": FieldValue.serverTimestamp()
        ])
        
        // Bildirim gönder
        let partnerDoc = try await db.collection("users").document(partnerId).getDocument()
        guard let partnerData = partnerDoc.data(),
              let partnerUsername = partnerData["username"] as? String else {
            return
        }
        
        let notificationId = UUID().uuidString
        let notificationData: [String: Any] = [
            "id": notificationId,
            "userId": partnerId,
            "title": "Eşleşme Reddedildi",
            "message": "Eşleşme isteğiniz reddedildi.",
            "type": "partnerRejected",
            "timestamp": FieldValue.serverTimestamp(),
            "isRead": false,
            "actionable": false
        ]
        
        try await db.collection("users").document(partnerId).collection("notifications").document(notificationId).setData(notificationData)
    }
    
    // Partner bağlantısını sonlandır
    func disconnectPartner(userId: String, partnerId: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "partnerId": FieldValue.delete(),
            "partnerUsername": FieldValue.delete(),
            "isPartnershipActive": false
        ])
        
        try await db.collection("users").document(partnerId).updateData([
            "partnerId": FieldValue.delete(),
            "partnerUsername": FieldValue.delete(),
            "isPartnershipActive": false
        ])
        
        // Bildirim gönder
        let userDoc = try await db.collection("users").document(userId).getDocument()
        guard let userData = userDoc.data(),
              let username = userData["username"] as? String else {
            return
        }
        
        let notificationId = UUID().uuidString
        let notificationData: [String: Any] = [
            "id": notificationId,
            "userId": partnerId,
            "title": "Partner Bağlantısı Sonlandırıldı",
            "message": "\(username) partner bağlantısını sonlandırdı.",
            "type": "partnerDisconnected",
            "timestamp": FieldValue.serverTimestamp(),
            "isRead": false,
            "actionable": false
        ]
        
        try await db.collection("users").document(partnerId).collection("notifications").document(notificationId).setData(notificationData)
    }
    
    // MARK: - Bildirim İşlemleri
    
    // Bildirimleri al
    func getNotifications(userId: String, limit: Int = 20) async throws -> [AppNotification] {
        let query = try await db.collection("users").document(userId).collection("notifications")
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        var notifications: [AppNotification] = []
        
        for document in query.documents {
            if let notification = parseNotification(document) {
                notifications.append(notification)
            }
        }
        
        return notifications
    }
    
    // Okunmamış bildirim sayısını al
    func getUnreadNotificationsCount(userId: String) async throws -> Int {
        let query = try await db.collection("users").document(userId).collection("notifications")
            .whereField("isRead", isEqualTo: false)
            .count
            .getAggregation(source: .server)
        
        return Int(truncating: query.count)
    }
    
    // Bildirimi okundu olarak işaretle
    func markNotificationAsRead(userId: String, notificationId: String) async throws {
        try await db.collection("users").document(userId).collection("notifications").document(notificationId).updateData([
            "isRead": true
        ])
    }
    
    // Tüm bildirimleri okundu olarak işaretle
    func markAllNotificationsAsRead(userId: String) async throws {
        let batch = db.batch()
        
        let query = try await db.collection("users").document(userId).collection("notifications")
            .whereField("isRead", isEqualTo: false)
            .getDocuments()
        
        for document in query.documents {
            let docRef = db.collection("users").document(userId).collection("notifications").document(document.documentID)
            batch.updateData(["isRead": true], forDocument: docRef)
        }
        
        try await batch.commit()
    }
    
    // MARK: - Helper Methods
    
    private func parseNotification(_ document: DocumentSnapshot) -> AppNotification? {
        guard let data = document.data() else { return nil }
        
        guard let id = data["id"] as? String,
              let title = data["title"] as? String,
              let message = data["message"] as? String,
              let typeString = data["type"] as? String,
              let timestamp = (data["timestamp"] as? Timestamp)?.dateValue(),
              let isRead = data["isRead"] as? Bool,
              let actionable = data["actionable"] as? Bool,
              let type = AppNotification.NotificationType(rawValue: typeString) else {
            return nil
        }
        
        let notificationData: AppNotification.NotificationData?
        
        if let rawData = data["data"] as? [String: Any] {
            notificationData = AppNotification.NotificationData(
                partnerId: rawData["partnerId"] as? String,
                partnerUsername: rawData["partnerUsername"] as? String,
                bookId: rawData["bookId"] as? String,
                bookTitle: rawData["bookTitle"] as? String,
                bookCoverURL: (rawData["bookCoverURL"] as? String).flatMap { URL(string: $0) },
                goalType: (rawData["goalType"] as? String).flatMap { ReadingGoalType(rawValue: $0) },
                progress: rawData["progress"] as? Double,
                target: rawData["target"] as? Int,
                streakDays: rawData["streakDays"] as? Int,
                deepLink: rawData["deepLink"] as? String
            )
        } else {
            notificationData = nil
        }
        
        return AppNotification(
            id: id,
            userId: document.reference.parent.parent?.documentID ?? "",
            title: title,
            message: message,
            type: type,
            timestamp: timestamp,
            isRead: isRead,
            data: notificationData,
            actionable: actionable
        )
    }
}