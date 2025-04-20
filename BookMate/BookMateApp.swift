// BookMateApp.swift
// BookMate
//
// Created by abdulsamed on 18.04.2025.
//

import SwiftUI
import CoreData
import FirebaseCore

@main
struct BookMateApp: App {
    // Core Data konfigürasyonu için AppDelegate
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    // View model'leri oluştur
    @StateObject private var bookViewModel = BookViewModel()
    @StateObject private var userViewModel = UserViewModel()
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        // Firebase'i yapılandırma
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bookViewModel)
                .environmentObject(userViewModel)
                .environmentObject(authViewModel)
        }
    }
}

// Core Data konfigürasyonu için AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Uygulama başladığında yapılacak özel işlemler
        print("BookMate uygulaması başlatıldı")
        
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Uygulama kapanırken Core Data bağlamını kaydet
        CoreDataManager.shared.saveContext()
    }
}

// Uygulama genelinde kullanılacak kimlik doğrulama view modeli
class AuthViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        // Mevcut kullanıcı oturumunu kontrol et
        checkCurrentUser()
    }
    
    func checkCurrentUser() {
        // FirebaseAuth'dan mevcut kullanıcıyı kontrol et
        // Bu kısım FirebaseAuth.Auth.auth().currentUser kullanılarak yapılır
        // Şimdilik basit tutuyoruz
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            self.currentUser = try await FirebaseService.shared.signIn(email: email, password: password)
            DispatchQueue.main.async {
                self.isAuthenticated = true
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func signUp(name: String, email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            self.currentUser = try await FirebaseService.shared.signUp(email: email, password: password, name: name)
            DispatchQueue.main.async {
                self.isAuthenticated = true
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func signOut() {
        do {
            try FirebaseService.shared.signOut()
            self.currentUser = nil
            self.isAuthenticated = false
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
} 