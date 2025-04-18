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
    @StateObject private var userViewModel = UserViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bookViewModel)
                .environmentObject(userViewModel)
        }
    }
}
