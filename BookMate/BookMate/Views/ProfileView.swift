import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var bookViewModel: BookViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Profil resmi ve isim
                    VStack(spacing: 15) {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text((userViewModel.currentUser?.username.prefix(1) ?? "U").uppercased())
                                    .font(.system(size: 40))
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                            )
                        
                        Text(userViewModel.currentUser?.username ?? "Kullanıcı")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(userViewModel.currentUser?.email ?? "kullanici@example.com")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    // Ayarlar bölümü
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Ayarlar")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        
                        Divider()
                        
                        // Örnek ayar seçenekleri
                        ForEach(["Hesap Bilgileri", "Bildirimler", "Tema", "Yardım", "Hakkında"], id: \.self) { setting in
                            HStack {
                                Text(setting)
                                    .padding()
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .padding(.trailing)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // İşlem
                            }
                            
                            Divider()
                        }
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Başarılar
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Başarılarım")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(["İlk Kitap", "Haftalık Okuyucu", "10 Kitap Kulübü"], id: \.self) { achievement in
                                    VStack(spacing: 10) {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 70, height: 70)
                                            .overlay(
                                                Image(systemName: "star.fill")
                                                    .font(.system(size: 30))
                                                    .foregroundColor(.white)
                                            )
                                        
                                        Text(achievement)
                                            .font(.subheadline)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.center)
                                            .frame(width: 100)
                                    }
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Çıkış butonu
                    Button(action: {
                        // Çıkış işlemi
                    }) {
                        Text("Çıkış Yap")
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Uygulama versiyonu
                    Text("BookMate v1.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .padding(.vertical)
            }
            .navigationBarTitle("Profil", displayMode: .inline)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(BookViewModel())
        .environmentObject(UserViewModel())
} 