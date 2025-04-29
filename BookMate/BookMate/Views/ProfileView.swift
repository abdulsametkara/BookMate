import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var bookViewModel: BookViewModel
    @EnvironmentObject var userViewModel: BookMate.UserViewModel
    
    @State private var showEditProfile = false
    @State private var showSettings = false
    
    private var userInitial: String {
        if let fullName = userViewModel.currentUser?.fullName, !fullName.isEmpty {
            return String(fullName.prefix(1).uppercased())
        } else if let username = userViewModel.currentUser?.username, !username.isEmpty {
            return String(username.prefix(1).uppercased())
        } else {
            return "U"
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ProfileCoverView(userInitial: userInitial, showSettings: $showSettings)
                
                ProfileInfoView(
                    userName: userViewModel.currentUser?.fullName ?? userViewModel.currentUser?.username ?? "Kullanıcı",
                    email: userViewModel.currentUser?.email ?? "kullanici@example.com",
                    bio: userViewModel.currentUser?.bio,
                    showEditProfile: $showEditProfile
                )
                
                // İstatistikler
                StatsGridView(statistics: userViewModel.currentUser?.statistics)
                    .padding()
                
                // Okuma hedefi
                if let readingGoal = userViewModel.currentUser?.readingGoal {
                    ReadingGoalView(readingGoal: readingGoal)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                }
                
                // Son okunan kitaplar
                RecentBooksView(books: bookViewModel.recentlyAddedBooks)
                    .padding(.horizontal)
                
                // Çıkış butonu
                Button(action: {
                    authViewModel.logout()
                }) {
                    Text("Çıkış Yap")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.9))
                        .cornerRadius(15)
                        .shadow(color: Color.red.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }
            .edgesIgnoringSafeArea(.top)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showEditProfile) {
        NavigationView {
                EditProfileView()
                    .environmentObject(userViewModel)
                    .navigationBarTitle("Profili Düzenle", displayMode: .inline)
                    .navigationBarItems(trailing: Button("Tamam") {
                        showEditProfile = false
                    })
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(userViewModel)
                .environmentObject(authViewModel)
        }
        .onAppear {
            // İlk olarak mevcut kullanıcı verilerini getir
            userViewModel.refreshUserData()
            
            // Sonra kullanıcı istatistiklerini BookViewModel'deki güncel veriler ile güncelle
            userViewModel.updateUserStatistics(with: bookViewModel)
            
            // UI'ı güncellemek için objectWillChange gönder
            DispatchQueue.main.async {
                userViewModel.objectWillChange.send()
                bookViewModel.objectWillChange.send()
            }
        }
    }
}

// Header view - üst kısım
struct ProfileCoverView: View {
    let userInitial: String
    @Binding var showSettings: Bool
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Kapak resmi alanı
            Rectangle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.blue.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing))
                .frame(height: 150)
            
            // Ayarlar butonu
            HStack {
                Spacer()
                
                Button(action: {
                    showSettings = true
                }) {
                    Image(systemName: "gear")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                .padding(.trailing)
                .padding(.bottom, 80)
            }
            
            // Profil resmi
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 110, height: 110)
                        .shadow(color: Color.black.opacity(0.1), radius: 5)
                    
                        Circle()
                        .fill(Color.blue.opacity(0.2))
                            .frame(width: 100, height: 100)
                            .overlay(
                            Text(userInitial)
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(.blue)
                        )
                }
                .offset(y: 40)
            }
        }
    }
}

// Kullanıcı bilgileri görünümü
struct ProfileInfoView: View {
    let userName: String
    let email: String
    let bio: String?
    @Binding var showEditProfile: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Boşluk (profil resmi için yer ayırma)
            Spacer()
                .frame(height: 50)
            
            // İsim
            Text(userName)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .padding(.top)
            
            // E-posta
            Text(email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                .padding(.bottom, 5)
            
            // Düzenle butonu
            Button(action: {
                showEditProfile = true
            }) {
                Text("Profili Düzenle")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(15)
            }
            .padding(.bottom, 10)
            
            // Biyografi
            if let bio = bio, !bio.isEmpty {
                Text(bio)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.bottom, 10)
            }
        }
    }
}

// İstatistik kartları görünümü
struct StatsGridView: View {
    let statistics: ReadingStatistics?
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 15) {
            // Okunan kitaplar
            StatCardView(
                title: "Okunan Kitaplar",
                value: "\(statistics?.totalBooksRead ?? 0)",
                icon: "book.fill",
                color: .blue
            )
            
            // Toplam sayfa
            StatCardView(
                title: "Okunan Sayfalar",
                value: "\(statistics?.totalPagesRead ?? 0)",
                icon: "doc.text.fill",
                color: .green
            )
            
            // Ortalama puan
            StatCardView(
                title: "Ortalama Puanlama",
                value: formatRating(statistics?.averageRating ?? 0),
                icon: "star.fill",
                color: .yellow
            )
            
            // Okuma serisi
            StatCardView(
                title: "Okuma Serisi",
                value: "\(statistics?.readingStreak ?? 0) gün",
                icon: "calendar",
                color: .orange
            )
        }
    }
    
    // Değerlendirme puanını formatla
    private func formatRating(_ rating: Double) -> String {
        if rating == 0 {
            return "0.0"  // Sıfır değerini 0.0 olarak göster
        } else {
            return String(format: "%.1f", rating)
        }
    }
}

// Okuma hedefi kartı
struct ReadingGoalView: View {
    let readingGoal: ReadingGoal
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Okuma Hedefi")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Hedefe göre farklı metin göster
                Group {
                    switch readingGoal.type {
                    case .booksPerYear:
                        Text("\(readingGoal.progress) / \(readingGoal.target) kitap")
                    case .booksPerMonth:
                        Text("\(readingGoal.progress) / \(readingGoal.target) kitap")
                    case .pagesPerDay:
                        Text("\(readingGoal.progress) / \(readingGoal.target) sayfa")
                    case .minutesPerDay:
                        Text("\(readingGoal.progress) / \(readingGoal.target) dakika")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                // İlerleme çubuğu
                VStack(alignment: .leading, spacing: 2) {
                    ProgressView(value: Double(readingGoal.progress), total: Double(readingGoal.target))
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(height: 8)
                    
                    // Kalan gün bilgisi
                    Text("\(readingGoal.remainingDays) gün kaldı")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Hedef türü
            VStack(alignment: .trailing) {
                Image(systemName: goalTypeIcon)
                    .font(.title)
                    .foregroundColor(.blue.opacity(0.7))
                
                Text(readingGoal.type.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // Hedef türüne göre ikon seç
    private var goalTypeIcon: String {
        switch readingGoal.type {
        case .booksPerYear:
            return "calendar"
        case .booksPerMonth:
            return "calendar.badge.clock"
        case .pagesPerDay:
            return "doc.text"
        case .minutesPerDay:
            return "timer"
        }
    }
}

// Son okunan kitaplar görünümü
struct RecentBooksView: View {
    let books: [GoogleBook]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                Text("Son Eklenen Kitaplar")
                    .font(.headline)
                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                NavigationLink(destination: LibraryView()) {
                    Text("Tümünü Gör")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            if books.isEmpty {
                Text("Henüz kitap eklemediniz")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                // Son 3 kitabı göster
                ForEach(Array(books.prefix(3).enumerated()), id: \.element.id) { index, book in
                    BookRowView(book: book, index: index, totalCount: min(3, books.count))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// Kitap satırı görünümü
struct BookRowView: View {
    let book: GoogleBook
    let index: Int
    let totalCount: Int
    
    var body: some View {
        VStack {
            HStack {
                // Kitap kapağı
                if let thumbnailURL = book.thumbnailURL {
                    AsyncImage(url: thumbnailURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 70)
                                .cornerRadius(5)
                        default:
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 50, height: 70)
                                .overlay(
                                    Image(systemName: "book.closed")
                                        .foregroundColor(.gray)
                                )
                        }
                    }
                } else {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 70)
                        .overlay(
                            Image(systemName: "book.closed")
                                .foregroundColor(.gray)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.system(size: 16, weight: .medium))
                        .lineLimit(1)
                    
                    Text(book.authorsText)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    if let finishedDate = book.finishedReading {
                        Text("Tamamlandı: \(formatDate(finishedDate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if book.readingStatus == .finished {
                    HStack(spacing: 1) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 12))
                        
                        Text("5/5") // sabit değer veya readingProgressPercentage ile ayarlanabilir
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 5)
            
            if index < totalCount - 1 {
                Divider()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
}

// İstatistik kartı görünümü
struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
                .padding(.bottom, 5)
            
            Text(value)
                .font(.system(size: 22, weight: .bold))
            
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .frame(height: 110)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
                                    .cornerRadius(12)
    }
}

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var userViewModel: BookMate.UserViewModel
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("isNotificationsEnabled") private var isNotificationsEnabled = true
    @State private var showDeleteAccountAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Görünüm")) {
                    Toggle("Karanlık Mod", isOn: $isDarkMode.animation())
                        .onChange(of: isDarkMode) { oldValue, newValue in
                            // Karanlık mod değiştiğinde tema güncellenir
                            DispatchQueue.main.async {
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let window = windowScene.windows.first {
                                    window.overrideUserInterfaceStyle = newValue ? .dark : .light
                                }
                            }
                        }
                }
                
                Section(header: Text("Bildirimler")) {
                    Toggle("Bildirimlere İzin Ver", isOn: $isNotificationsEnabled)
                }
                
                Section(header: Text("Hesap")) {
                    NavigationLink(destination: ChangePasswordView()
                        .environmentObject(authViewModel)) {
                        Text("Şifre Değiştir")
                    }
                    
                    Button(action: {
                        showDeleteAccountAlert = true
                    }) {
                        Text("Hesabı Sil")
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button(action: {
                        authViewModel.logout()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Çıkış Yap")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Ayarlar")
            .navigationBarItems(trailing: Button("Kapat") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showDeleteAccountAlert) {
                Alert(
                    title: Text("Hesabı Sil"),
                    message: Text("Hesabınızı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz."),
                    primaryButton: .destructive(Text("Sil")) {
                        // Hesabı silme işlemi
                        authViewModel.deleteAccount()
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel(Text("İptal"))
                )
            }
        }
    }
}

struct ChangePasswordView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showSuccessAlert = false
    
    var body: some View {
        Form {
            Section(header: Text("Mevcut Şifre")) {
                SecureField("Şu anki şifre", text: $currentPassword)
            }
            
            Section(header: Text("Yeni Şifre")) {
                SecureField("Yeni şifre", text: $newPassword)
                SecureField("Yeni şifreyi doğrula", text: $confirmPassword)
            }
            
            Section {
                Button(action: {
                    updatePassword()
                }) {
                    Text("Şifreyi Güncelle")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.blue)
                }
            }
        }
        .navigationTitle("Şifre Değiştir")
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Hata"),
                message: Text(errorMessage),
                dismissButton: .default(Text("Tamam"))
            )
        }
        .alert("Şifre Güncellendi", isPresented: $showSuccessAlert) {
            Button("Tamam") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Şifreniz başarıyla güncellenmiştir.")
        }
    }
    
    private func updatePassword() {
        // Şifre alanlarını kontrol et
        if currentPassword.isEmpty {
            errorMessage = "Mevcut şifrenizi giriniz."
            showErrorAlert = true
            return
        }
        
        if newPassword.isEmpty || confirmPassword.isEmpty {
            errorMessage = "Yeni şifre alanları boş olamaz."
            showErrorAlert = true
            return
        }
        
        if newPassword != confirmPassword {
            errorMessage = "Yeni şifreler eşleşmiyor."
            showErrorAlert = true
            return
        }
        
        if newPassword.count < 6 {
            errorMessage = "Şifreniz en az 6 karakter olmalıdır."
            showErrorAlert = true
            return
        }
        
        // Şifre güncelleme işlemi
        let result = authViewModel.updatePassword(currentPassword: currentPassword, newPassword: newPassword)
        
        if result {
            showSuccessAlert = true
        } else {
            errorMessage = "Mevcut şifreniz doğru değil veya şifre değiştirme işlemi başarısız oldu."
            showErrorAlert = true
        }
    }
}

#Preview {
    let bookVM = BookViewModel()
    let userVM = BookMate.UserViewModel()
    let authVM = AuthViewModel()
    return ProfileView()
        .environmentObject(bookVM)
        .environmentObject(userVM)
        .environmentObject(authVM)
} 