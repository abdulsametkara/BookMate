// BookMateApp.swift
// BookMate
//
// Created by abdulsamed on 18.04.2025.
//

import SwiftUI
import CoreData

@main
struct BookMateApp: App {
    // Core Data konfigürasyonu için AppDelegate
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    // View model'leri oluştur
    @StateObject private var bookViewModel = BookViewModel()
    @StateObject private var userViewModel = UserViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bookViewModel)
                .environmentObject(userViewModel)
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