import Foundation
import Combine
import SwiftUI

class PartnerViewModel: ObservableObject {
    @Published var currentPartner: Partner?
    @Published var partnerRequests: [PartnerRequest] = []
    @Published var partnerActivities: [PartnerActivity] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var partnerCode: String = ""
    @Published var isGeneratingCode: Bool = false
    @Published var isSendingRequest: Bool = false
    
    // Partnere sahip olup olmadığını kontrol eder
    var hasPartner: Bool {
        return currentPartner != nil
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // İleride bu kısımda partner verilerini yükleyeceğiz
    }
    
    // Partner bağlantısını sonlandır
    func disconnectPartner(partnerId: String) {
        guard let currentUser = UserSession.shared.getCurrentUser() else {
            self.errorMessage = "Kullanıcı bilgisi alınamadı"
            return
        }
        
        isLoading = true
        
        Task {
            do {
                try await FirebaseService.shared.disconnectPartner(userId: currentUser.id.uuidString, partnerId: partnerId)
                
                DispatchQueue.main.async {
                    self.currentPartner = nil
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Partner bağlantısı sonlandırılamadı: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    // Kod ile partner isteği gönder
    func sendPartnerRequest(code: String) {
        guard let currentUser = UserSession.shared.getCurrentUser() else {
            self.errorMessage = "Kullanıcı bilgisi alınamadı"
            return
        }
        
        isSendingRequest = true
        
        Task {
            do {
                if let partnerId = try await FirebaseService.shared.findUserByPartnerCode(code: code) {
                    try await FirebaseService.shared.sendPartnerRequest(fromUserId: currentUser.id.uuidString, toUserId: partnerId)
                    
                    DispatchQueue.main.async {
                        self.isSendingRequest = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Partner kodu bulunamadı"
                        self.isSendingRequest = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Partner isteği gönderilemedi: \(error.localizedDescription)"
                    self.isSendingRequest = false
                }
            }
        }
    }
    
    // E-posta ile partner isteği gönder
    func sendPartnerRequest(toEmail: String) {
        guard let currentUser = UserSession.shared.getCurrentUser() else {
            self.errorMessage = "Kullanıcı bilgisi alınamadı"
            return
        }
        
        isSendingRequest = true
        
        // Burada e-posta ile kullanıcı bulma ve istek gönderme implementasyonu olacak
        // Örnek olarak simulasyon amaçlı
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isSendingRequest = false
            self.errorMessage = "Demo sürümünde e-posta ile partner ekleme özelliği mevcut değil"
        }
    }
} 