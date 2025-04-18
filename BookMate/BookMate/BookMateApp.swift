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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bookViewModel)
                .environmentObject(userViewModel)
        }
    }
}
