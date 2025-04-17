import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var isEditingProfile = false
    
    // Tercihler için yerel state
    @State private var notificationEnabled = true
    @State private var darkModeEnabled = false
    @State private var goals = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profil resmi ve bilgileri
                    VStack(spacing: 15) {
                        // Profil resmi
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 100, height: 100)
                            
                            Text((userViewModel.currentUser?.name.prefix(1) ?? "K"))
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            
                            // Düzenleme butonu
                            if isEditingProfile {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 30, height: 30)
                                            .overlay(
                                                Image(systemName: "camera.fill")
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 15))
                                            )
                                            .offset(x: 5, y: 5)
                                    }
                                }
                                .frame(width: 100, height: 100)
                            }
                        }
                        
                        // Kullanıcı adı
                        if isEditingProfile {
                            TextField("Adınız", text: Binding(
                                get: { userViewModel.currentUser?.name ?? "" },
                                set: { userViewModel.updateUserName($0) }
                            ))
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        } else {
                            Text(userViewModel.currentUser?.name ?? "Kullanıcı")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        // Eş bilgisi
                        if let partnerName = userViewModel.currentUser?.partnerName, !partnerName.isEmpty {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                Text("Eşleşilen: \(partnerName)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Düzenleme butonları
                        if isEditingProfile {
                            HStack(spacing: 20) {
                                Button(action: {
                                    isEditingProfile = false
                                }) {
                                    Text("İptal")
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Color.gray.opacity(0.2))
                                        .foregroundColor(.primary)
                                        .cornerRadius(8)
                                }
                                
                                Button(action: {
                                    isEditingProfile = false
                                    // Profil bilgilerini kaydet - viewModel üzerinden zaten yapılıyor
                                }) {
                                    Text("Kaydet")
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                            }
                        } else {
                            Button(action: {
                                isEditingProfile = true
                            }) {
                                Text("Profili Düzenle")
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Okuma başarıları
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Başarılarım")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                if let achievements = userViewModel.currentUser?.achievements {
                                    ForEach(achievements) { achievement in
                                        AchievementView(
                                            title: achievement.title,
                                            description: achievement.description,
                                            isUnlocked: achievement.isUnlocked,
                                            icon: achievement.icon
                                        )
                                    }
                                } else {
                                    ForEach(0..<3) { i in
                                        AchievementView(
                                            title: ["İlk Kitap", "Haftalık Okuyucu", "10 Kitap Kulübü"][i],
                                            description: ["İlk kitabını tamamla", "Bir hafta boyunca her gün oku", "10 kitap tamamla"][i],
                                            isUnlocked: i == 0,
                                            icon: ["book", "calendar", "books.vertical"][i]
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Ayarlar
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Ayarlar")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ToggleSettingRow(
                            title: "Bildirimler",
                            isOn: Binding(
                                get: { userViewModel.currentUser?.preferences.notificationsEnabled ?? true },
                                set: { 
                                    if var preferences = userViewModel.currentUser?.preferences {
                                        preferences.notificationsEnabled = $0
                                        userViewModel.updateUserPreferences(preferences: preferences)
                                    }
                                }
                            ),
                            icon: "bell.fill"
                        )
                        
                        ToggleSettingRow(
                            title: "Karanlık Mod",
                            isOn: Binding(
                                get: { userViewModel.currentUser?.preferences.darkModeEnabled ?? false },
                                set: { 
                                    if var preferences = userViewModel.currentUser?.preferences {
                                        preferences.darkModeEnabled = $0
                                        userViewModel.updateUserPreferences(preferences: preferences)
                                    }
                                }
                            ),
                            icon: "moon.fill"
                        )
                        
                        ToggleSettingRow(
                            title: "Okuma Hedefleri",
                            isOn: Binding(
                                get: { userViewModel.currentUser?.preferences.goalsEnabled ?? true },
                                set: { 
                                    if var preferences = userViewModel.currentUser?.preferences {
                                        preferences.goalsEnabled = $0
                                        userViewModel.updateUserPreferences(preferences: preferences)
                                    }
                                }
                            ),
                            icon: "target"
                        )
                        
                        NavigationSettingRow(title: "Hesap", icon: "person.fill") {
                            AccountSettingsView()
                        }
                        
                        NavigationSettingRow(title: "Gizlilik", icon: "lock.fill") {
                            PrivacySettingsView()
                        }
                        
                        NavigationSettingRow(title: "Yardım", icon: "questionmark.circle.fill") {
                            HelpCenterView()
                        }
                    }
                    .padding(.vertical)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Çıkış butonu
                    Button(action: {
                        // Oturumu kapat
                        AuthenticationManager.shared.logout()
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                            Text("Çıkış Yap")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    // Sürüm bilgisi
                    Text("BookMate v1.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .padding(.vertical)
            }
            .navigationTitle("Profil")
            .navigationBarItems(
                trailing: userViewModel.currentUser?.partnerName == nil ? 
                    NavigationLink(destination: PartnerInviteView()) {
                        Image(systemName: "person.badge.plus")
                    } : nil
            )
            .onAppear {
                userViewModel.loadUser()
                
                // Kullanıcı verisi gelince yerel state'leri güncelle
                if let preferences = userViewModel.currentUser?.preferences {
                    notificationEnabled = preferences.notificationsEnabled
                    darkModeEnabled = preferences.darkModeEnabled
                    goals = preferences.goalsEnabled
                }
            }
        }
    }
}

struct AchievementView: View {
    let title: String
    let description: String
    let isUnlocked: Bool
    let icon: String
    
    var body: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(isUnlocked ? Color.blue : Color.gray.opacity(0.3))
                .frame(width: 70, height: 70)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 30))
                        .foregroundColor(isUnlocked ? .white : .gray)
                )
            
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 120)
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct ToggleSettingRow: View {
    let title: String
    @Binding var isOn: Bool
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 30, height: 30)
                .foregroundColor(.blue)
            
            Text(title)
                .fontWeight(.medium)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.horizontal)
        .padding(.vertical, 5)
    }
}

struct NavigationSettingRow<Destination: View>: View {
    let title: String
    let icon: String
    let destination: Destination
    
    init(title: String, icon: String, @ViewBuilder destination: () -> Destination) {
        self.title = title
        self.icon = icon
        self.destination = destination()
    }
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 30, height: 30)
                    .foregroundColor(.blue)
                
                Text(title)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .padding(.vertical, 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Placeholder görünümler
struct AccountSettingsView: View {
    var body: some View {
        Text("Hesap Ayarları")
            .navigationTitle("Hesap")
    }
}

struct PrivacySettingsView: View {
    var body: some View {
        Text("Gizlilik Ayarları")
            .navigationTitle("Gizlilik")
    }
}

struct HelpCenterView: View {
    var body: some View {
        Text("Yardım Merkezi")
            .navigationTitle("Yardım")
    }
}

struct PartnerInviteView: View {
    @State private var email = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Eşinizi Davet Edin")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Eşinizin e-posta adresini girerek davet gönderin.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            TextField("E-posta adresi", text: $email)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
            Button(action: {
                // Davet gönder
            }) {
                Text("Davet Gönder")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .disabled(email.isEmpty)
        }
        .padding()
        .navigationTitle("Eş Daveti")
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(UserViewModel())
    }
} 