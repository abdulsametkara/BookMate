import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    let tabs = [
        TabItem(title: "Ana Sayfa", icon: "house", selectedIcon: "house.fill"),
        TabItem(title: "Kütüphane", icon: "books.vertical", selectedIcon: "books.vertical.fill"),
        TabItem(title: "Koleksiyonlar", icon: "folder", selectedIcon: "folder.fill"),
        TabItem(title: "Aktivite", icon: "bell", selectedIcon: "bell.fill", badgeValue: 2),
        TabItem(title: "Profil", icon: "person", selectedIcon: "person.fill")
    ]
    
    // Gerekli view model'leri oluştur
    @StateObject private var userViewModel = UserViewModel()
    @StateObject private var bookViewModel = BookViewModel()
    @StateObject private var collectionViewModel = BookCollectionViewModel()
    
    var body: some View {
        CustomTabView(selectedTab: $selectedTab, tabs: tabs) { index in
            switch index {
            case 0:
                HomeView(bookViewModel: bookViewModel, userViewModel: userViewModel)
                    .environmentObject(collectionViewModel)
            case 1:
                MyLibraryView()
                    .environmentObject(bookViewModel)
                    .environmentObject(collectionViewModel)
                    .environmentObject(userViewModel)
            case 2:
                CollectionsView()
                    .environmentObject(collectionViewModel)
                    .environmentObject(bookViewModel)
            case 3:
                ActivityView()
                    .environmentObject(userViewModel)
            case 4:
                ProfileView()
                    .environmentObject(userViewModel)
                    .environmentObject(bookViewModel)
            default:
                EmptyView()
            }
        }
    }
}

struct CollectionsView: View {
    @EnvironmentObject var collectionViewModel: BookCollectionViewModel
    @State private var showingCreateCollectionSheet = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                if collectionViewModel.collections.isEmpty {
                    emptyStateView
                } else {
                    collectionsListView
                }
            }
            .navigationTitle("Koleksiyonlarım")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateCollectionSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateCollectionSheet) {
                CreateCollectionView(viewModel: collectionViewModel)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 70))
                .foregroundColor(.gray)
            
            Text("Henüz koleksiyon oluşturmadınız")
                .font(.title3)
                .bold()
            
            Text("Kitaplarınızı düzenlemek için koleksiyonlar oluşturun.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: {
                showingCreateCollectionSheet = true
            }) {
                Text("Koleksiyon Oluştur")
                    .font(.headline)
                    .padding()
                    .background(AppColors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 16)
        }
        .padding()
    }
    
    private var collectionsListView: some View {
        ScrollView {
            SearchBar(text: $searchText, placeholder: "Koleksiyon ara...")
                .padding()
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                ForEach(filteredCollections) { collection in
                    NavigationLink(destination: CollectionDetailView(viewModel: collectionViewModel, collectionId: collection.id)) {
                        CollectionCard(collection: collection)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }
    
    private var filteredCollections: [BookCollection] {
        if searchText.isEmpty {
            return collectionViewModel.collections
        } else {
            return collectionViewModel.collections.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                ($0.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
}

struct CollectionCard: View {
    let collection: BookCollection
    
    var body: some View {
        VStack(alignment: .leading) {
            // Cover images collage
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .aspectRatio(1, contentMode: .fit)
                    .cornerRadius(12)
                
                if collection.coverImages.isEmpty {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.primary.opacity(0.7))
                } else {
                    // Show first cover image if available
                    if let firstCover = collection.coverImages.first {
                        AsyncImage(url: firstCover) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(AppColors.primary.opacity(0.7))
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .aspectRatio(1, contentMode: .fill)
                        .cornerRadius(12)
                    }
                }
                
                // If shared with partner, show badge
                if collection.isSharedWithPartner {
                    VStack {
                        HStack {
                            Spacer()
                            
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.white)
                                .padding(6)
                                .background(AppColors.primary)
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                    }
                    .padding(8)
                }
            }
            
            // Collection name and details
            VStack(alignment: .leading, spacing: 4) {
                Text(collection.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("\(collection.bookCount) kitap")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // If there's a meaningful completion percentage, show it
                if collection.bookCount > 0 && collection.completionPercentage > 0 {
                    ProgressView(value: collection.completionPercentage / 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: AppColors.primary))
                        .frame(height: 4)
                }
            }
            .padding(.top, 8)
        }
        .frame(width: 160)
        .padding(.bottom, 8)
    }
}

struct CreateCollectionView: View {
    @ObservedObject var viewModel: BookCollectionViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var collectionName = ""
    @State private var collectionDescription = ""
    @State private var isSharedWithPartner = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Koleksiyon Bilgileri")) {
                    TextField("Koleksiyon adı", text: $collectionName)
                    
                    TextField("Açıklama (isteğe bağlı)", text: $collectionDescription)
                        .frame(height: 80)
                }
                
                Section {
                    Toggle("Eşimle paylaş", isOn: $isSharedWithPartner)
                }
                
                Section {
                    Button(action: createCollection) {
                        Text("Koleksiyon Oluştur")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.blue)
                    }
                    .disabled(collectionName.isEmpty)
                }
            }
            .navigationTitle("Yeni Koleksiyon")
            .navigationBarItems(trailing: Button("İptal") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func createCollection() {
        viewModel.createCollection(
            name: collectionName,
            description: collectionDescription.isEmpty ? nil : collectionDescription,
            isSharedWithPartner: isSharedWithPartner
        )
        presentationMode.wrappedValue.dismiss()
    }
}

struct ActivityView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segment control for switching between notifications and activity feed
                Picker("", selection: $selectedTab) {
                    Text("Partner Aktiviteleri").tag(0)
                    Text("Bildirimler").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top, 8)
                
                if selectedTab == 0 {
                    activityFeedView
                } else {
                    notificationsView
                }
            }
            .navigationTitle("Aktivite")
        }
    }
    
    private var activityFeedView: some View {
        ScrollView {
            if let partner = userViewModel.currentUser?.partner, userViewModel.partnerActivities.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 70))
                        .foregroundColor(.gray)
                    
                    Text("Henüz aktivite yok")
                        .font(.title3)
                        .bold()
                    
                    Text("\(partner.username) bir kitap okumaya başladığında burada görebileceksiniz.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if userViewModel.currentUser?.partner == nil {
                VStack(spacing: 16) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 70))
                        .foregroundColor(.gray)
                    
                    Text("Eş bağlantısı yok")
                        .font(.title3)
                        .bold()
                    
                    Text("Aktiviteleri görebilmek için bir okuma eşi ile bağlantı kurmanız gerekiyor.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    NavigationLink(destination: PartnerConnectionView()) {
                        Text("Eş Bağlantısı Kur")
                            .font(.headline)
                            .padding()
                            .background(AppColors.primary)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 16)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(userViewModel.partnerActivities) { activity in
                        ActivityFeedItem(activity: activity)
                        
                        Divider()
                            .padding(.leading, 70)
                    }
                }
                .padding()
            }
        }
    }
    
    private var notificationsView: some View {
        ScrollView {
            if userViewModel.notifications.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 70))
                        .foregroundColor(.gray)
                    
                    Text("Bildirim yok")
                        .font(.title3)
                        .bold()
                    
                    Text("Şu anda hiç bildiriminiz bulunmuyor.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(userViewModel.notifications) { notification in
                        PartnerNotificationItem(
                            notification: notification,
                            onAccept: {
                                userViewModel.acceptNotification(notification)
                            },
                            onDismiss: {
                                userViewModel.dismissNotification(notification.id)
                            }
                        )
                    }
                }
                .padding()
            }
        }
    }
}

struct PartnerConnectionView: View {
    @State private var partnerEmail = ""
    @State private var showingQRCode = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Okuma eşi ile bağlantı kurun")
                .font(.title2)
                .bold()
                .padding(.top, 40)
            
            Text("Eşinizle birlikte kitap okumak ve okuma aktivitelerini paylaşmak için bağlantı kurun.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Divider()
                .padding(.vertical, 20)
            
            // E-posta ile davet
            VStack(alignment: .leading, spacing: 8) {
                Text("E-posta ile davet gönder")
                    .font(.headline)
                
                RoundedTextField(
                    title: "Eşinizin e-posta adresi",
                    text: $partnerEmail,
                    keyboardType: .emailAddress,
                    autocapitalization: .none,
                    icon: "envelope"
                )
                
                Button(action: {
                    // E-posta davet gönderme işlemi
                }) {
                    Text("Davet Gönder")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(partnerEmail.isEmpty)
            }
            .padding()
            
            Divider()
                .padding(.vertical, 10)
            
            // QR kod ile davet
            VStack(spacing: 12) {
                Text("veya")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    showingQRCode = true
                }) {
                    HStack {
                        Image(systemName: "qrcode")
                        Text("QR Kod ile Davet Et")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                }
            }
            .padding()
            
            Spacer()
        }
        .sheet(isPresented: $showingQRCode) {
            QRCodeView()
        }
    }
}

struct QRCodeView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Örnek QR kod
                Image(systemName: "qrcode")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)
                    .padding()
                
                Text("Bu QR kodu eşinizin taraması için gösterin")
                    .font(.headline)
                
                Text("Eşiniz QR kodu taradığında, bağlantı isteği size bildirim olarak gelecektir.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Bağlantı QR Kodu")
            .navigationBarItems(trailing: Button("Kapat") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
} 