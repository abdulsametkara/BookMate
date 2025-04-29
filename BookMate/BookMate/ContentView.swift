//
//  ContentView.swift
//  BookMate
//
//  Created by abdulsamed on 18.04.2025.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject var bookViewModel = BookViewModel()
    @StateObject var userViewModel = BookMate.UserViewModel()
    @StateObject var readingTimerViewModel = ReadingTimerViewModel()
    @StateObject var libraryViewModel = LibraryViewModel()
    @State var selectedTab: Int = 0
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    // Auth ViewModel ekle
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        // Oturum durumuna göre farklı view'lar göster
        Group {
            if authViewModel.isAuthenticated {
                mainTabView
                    .onAppear {
                        // Kullanıcı oturum açtığında kullanıcı bilgilerini yenile
                        userViewModel.refreshUserData()
                        // İstatistikleri güncelle
                        userViewModel.updateUserStatistics(with: bookViewModel)
                        // Tema ayarlarını uygula
                        applyThemeSettings()
                    }
            } else {
                LoginView()
            }
        }
        .onAppear {
            // Uygulama başlatıldığında tema ayarlarını uygula
            applyThemeSettings()
        }
    }
    
    // Tema ayarlarını uygula
    private func applyThemeSettings() {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
            }
        }
    }
    
    // Ana TabView'u ayrı bir computed property olarak tanımla
    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Ana Sayfa", systemImage: "house.fill")
                }
                .tag(0)
                .onAppear {
                    // Ana sayfa açıldığında kitap verileri güncellensin
                    saveBookProgressData()
                }
            
            LibraryView()
                .tabItem {
                    Label("Kütüphane", systemImage: "books.vertical.fill")
                }
                .tag(1)
                .onAppear {
                    // Kütüphane açıldığında kitap verileri güncellensin
                    saveBookProgressData()
                }
            
            ReadingTimerView()
                .tabItem {
                    Label("Zamanlayıcı", systemImage: "timer")
                }
                .tag(2)
                .environmentObject(bookViewModel)
                .environmentObject(libraryViewModel)
                .onAppear {
                    // Kitap ilerleme verilerini kaydet
                    saveBookProgressData()
                }
            
            WishlistView()
                .tabItem {
                    Label("İstek Listem", systemImage: "heart.fill")
                }
                .tag(3)
            
            // ProfileView'u basitleştirelim
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("Profil", systemImage: "person.fill")
            }
            .tag(4)
        }
        .environmentObject(bookViewModel)
        .environmentObject(userViewModel)
        .environmentObject(readingTimerViewModel)
        .environmentObject(libraryViewModel)
        .onAppear {
            // Uygulama açılışında kitap ilerleme verilerini kaydet
            saveBookProgressData()
        }
    }
    
    // Kitap ilerleme verilerini kaydetme fonksiyonu
    private func saveBookProgressData() {
        // Yeni eklenen kitapları kütüphaneye senkronize et
        bookViewModel.synchronizeBooks()
        
        // Her kitap için ilerleme kaydedildiğinden emin ol
        bookViewModel.saveData()
    }
}

struct ProfileHeaderView: View {
    let user: User
    
    var body: some View {
        VStack(spacing: 15) {
            // Profil fotoğrafı
            if let photoURL = user.profilePhotoURL,
               let url = URL(string: photoURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    default:
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.blue)
                    }
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
            }
            
            // Kullanıcı adı
            Text(user.displayName)
                .font(.title2)
                .fontWeight(.bold)
            
            // Üyelik tarihi
            Text("Üyelik: \(formattedDate(user.joinDate))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Biyografi
            if let bio = user.bio {
                Text(bio)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.top, 5)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
}

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userViewModel: BookMate.UserViewModel
    
    @State private var username: String = ""
    @State private var fullName: String = ""
    @State private var bio: String = ""
    @State private var showSuccessAlert = false
    
    var body: some View {
        Form {
            Section(header: Text("Profil Bilgileri")) {
                TextField("Kullanıcı Adı", text: $username)
                TextField("Tam Ad", text: $fullName)
                
                ZStack(alignment: .topLeading) {
                    if bio.isEmpty {
                        Text("Biyografi")
                            .foregroundColor(Color(.placeholderText))
                            .padding(.top, 8)
                            .padding(.leading, 4)
                    }
                    
                    TextEditor(text: $bio)
                        .frame(minHeight: 100)
                }
            }
            
            Section {
                Button("Kaydet") {
                    // Değişiklikleri kaydet
                    saveProfileChanges()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(.blue)
                
                Button("İptal") {
                    presentationMode.wrappedValue.dismiss()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Profili Düzenle")
        .onAppear {
            if let user = userViewModel.currentUser {
                username = user.username
                fullName = user.fullName ?? ""
                bio = user.bio ?? ""
            }
        }
        .alert("Profil Güncellendi", isPresented: $showSuccessAlert) {
            Button("Tamam") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Profil bilgileriniz başarıyla güncellendi.")
        }
    }
    
    private func saveProfileChanges() {
        guard var user = userViewModel.currentUser else { return }
        
        // Kullanıcı bilgilerini güncelle
        user.username = username
        user.fullName = fullName.isEmpty ? nil : fullName
        user.bio = bio.isEmpty ? nil : bio
        
        // UserViewModel üzerinden değişiklikleri kaydet
        userViewModel.updateUserProfile(user)
        
        // Başarı mesajını göster
        showSuccessAlert = true
    }
}

// ProfileView yapısını kaldırdık, artık ayrı bir dosya olarak var

#Preview {
    let bookVM = BookViewModel()
    let userVM = BookMate.UserViewModel()
    let authVM = AuthViewModel()
    return ContentView()
        .environmentObject(bookVM)
        .environmentObject(userVM)
        .environmentObject(authVM)
}
