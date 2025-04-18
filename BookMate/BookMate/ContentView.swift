//
//  ContentView.swift
//  BookMate
//
//  Created by abdulsamed on 18.04.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject var bookViewModel = BookViewModel()
    @StateObject var userViewModel = BookMate.UserViewModel()
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Ana Sayfa", systemImage: "house.fill")
                }
            
            LibraryView()
                .tabItem {
                    Label("Kütüphane", systemImage: "books.vertical.fill")
                }
            
            WishlistView()
                .tabItem {
                    Label("İstek Listem", systemImage: "heart.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person.fill")
                }
        }
        .environmentObject(bookViewModel)
        .environmentObject(userViewModel)
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
    @State private var bio: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("Profil Bilgileri")) {
                TextField("Kullanıcı Adı", text: $username)
                
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
                    presentationMode.wrappedValue.dismiss()
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
                bio = user.bio ?? ""
            }
        }
    }
}

#Preview {
    let bookVM = BookViewModel()
    let userVM = BookMate.UserViewModel()
    return ContentView()
        .environmentObject(bookVM)
        .environmentObject(userVM)
}
