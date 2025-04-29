//
//  BookMateApp.swift
//  BookMate
//
//  Created by abdulsamed on 18.04.2025.
//

import SwiftUI
import CoreData

@main
struct BookMateApp: App {
    // View model'leri oluştur
    @StateObject private var bookViewModel = BookViewModel()
    // Use a local variable to avoid ambiguity
    @StateObject private var userViewModel: BookMate.UserViewModel = {
        return BookMate.UserViewModel()
    }()
    
    // Auth view model ekle
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        // ViewModels arası bağlantıyı kur
        bookViewModel.userViewModel = userViewModel
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bookViewModel)
                .environmentObject(userViewModel)
                .environmentObject(authViewModel)
                .onAppear {
                    // Verileri yükle
                    bookViewModel.synchronizeBooks()
                    userViewModel.refreshUserData()
                    
                    // İstatistikleri güncelle
                    if userViewModel.isLoggedIn {
                        userViewModel.updateUserStatistics(with: bookViewModel)
                    }
                }
        }
    }
}
