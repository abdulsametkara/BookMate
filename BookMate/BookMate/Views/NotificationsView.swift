import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var notificationViewModel: NotificationViewModel
    @EnvironmentObject var partnerViewModel: PartnerViewModel
    @State private var showSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Ana içerik
                VStack {
                    if notificationViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                            .padding()
                    } else if notificationViewModel.notifications.isEmpty {
                        // Bildirim yoksa
                        emptyStateView
                    } else {
                        // Bildirimler listesi
                        notificationsList
                    }
                }
                
                // Hata mesajı
                if let errorMessage = notificationViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(10)
                        .padding()
                        .transition(.move(edge: .top))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                notificationViewModel.errorMessage = nil
                            }
                        }
                }
            }
            .navigationTitle("Bildirimler")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        // Tümünü okundu olarak işaretle butonu
                        if !notificationViewModel.notifications.isEmpty {
                            Button(action: {
                                notificationViewModel.markAllAsRead()
                            }) {
                                Text("Tümünü Okundu İşaretle")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        // Ayarlar butonu
                        Button(action: {
                            showSettings = true
                        }) {
                            Image(systemName: "gear")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .onAppear {
                notificationViewModel.loadNotifications()
            }
            .sheet(isPresented: $showSettings) {
                NotificationSettingsView()
            }
            .refreshable {
                notificationViewModel.loadNotifications()
            }
        }
    }
    
    // Bildirim listesi görünümü
    private var notificationsList: some View {
        List {
            ForEach(notificationViewModel.notifications) { notification in
                NotificationRow(notification: notification)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        notificationViewModel.handleNotificationAction(notification: notification)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            // Sil butonu (opsiyonel)
                        } label: {
                            Label("Sil", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        if !notification.isRead {
                            Button {
                                notificationViewModel.markAsRead(notificationId: notification.id)
                            } label: {
                                Label("Okundu", systemImage: "checkmark")
                            }
                            .tint(.blue)
                        }
                    }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    // Bildirim olmadığında gösterilen boş durum
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "bell.slash")
                .font(.system(size: 70))
                .foregroundColor(.gray)
                .padding()
            
            Text("Henüz Bildirim Yok")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Bildirimleriniz burada görünecek. Partner eşleştirme, hedef bildirimleri ve başarılar hakkında bildirimler alacaksınız.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            // Bildirim izinlerini kontrol et
            Button(action: {
                notificationViewModel.requestNotificationPermission { granted in
                    print("Bildirim izni: \(granted ? "verildi" : "reddedildi")")
                }
            }) {
                Text("Bildirimleri Etkinleştir")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.horizontal, 40)
            }
            .padding(.bottom, 40)
        }
    }
}

// Bildirim satırı bileşeni
struct NotificationRow: View {
    let notification: AppNotification
    
    var body: some View {
        HStack(spacing: 15) {
            // Bildirim ikonu
            notificationIcon(type: notification.type)
                .font(.title2)
                .foregroundColor(notification.isRead ? .gray : .blue)
                .frame(width: 40, height: 40)
                .background(notification.isRead ? Color.gray.opacity(0.1) : Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 5) {
                // Bildirim başlığı
                Text(notification.title)
                    .font(.headline)
                    .foregroundColor(notification.isRead ? .secondary : .primary)
                
                // Bildirim mesajı
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Zaman
                Text(notification.timestamp.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Okunmamış işareti
            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.vertical, 5)
        .opacity(notification.isRead ? 0.8 : 1.0)
    }
    
    // Bildirim türüne göre ikon
    private func notificationIcon(type: AppNotification.NotificationType) -> some View {
        switch type {
        case .partnerRequest:
            return Image(systemName: "person.badge.plus")
        case .partnerAccepted:
            return Image(systemName: "person.2.fill")
        case .partnerRejected:
            return Image(systemName: "person.badge.minus")
        case .partnerActivity:
            return Image(systemName: "book.fill")
        case .goalAchieved:
            return Image(systemName: "flag.fill")
        case .streakUpdate:
            return Image(systemName: "flame.fill")
        case .milestone:
            return Image(systemName: "star.fill")
        case .reminderToRead:
            return Image(systemName: "alarm")
        case .bookRecommendation:
            return Image(systemName: "heart.text.square.fill")
        case .systemNotification:
            return Image(systemName: "bell.fill")
        }
    }
}

// Bildirim ayarları görünümü
struct NotificationSettingsView: View {
    @EnvironmentObject var notificationViewModel: NotificationViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var notificationsEnabled = true
    @State private var partnerRequestsEnabled = true
    @State private var partnerActivitiesEnabled = true
    @State private var goalUpdatesEnabled = true
    @State private var streakUpdatesEnabled = true
    @State private var milestonesEnabled = true
    @State private var dailyRemindersEnabled = false
    @State private var recommendationsEnabled = true
    @State private var systemUpdatesEnabled = true
    @State private var selectedSound = "default"
    @State private var reminderTime = Date().addingTimeInterval(18 * 3600) // Akşam 6
    @State private var quietHoursStart = Date().addingTimeInterval(22 * 3600) // Gece 10
    @State private var quietHoursEnd = Date().addingTimeInterval(8 * 3600) // Sabah 8
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Bildirim İzinleri")) {
                    Toggle("Bildirimlere İzin Ver", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { oldValue, newValue in
                            if newValue {
                                notificationViewModel.requestNotificationPermission { granted in
                                    if !granted {
                                        notificationsEnabled = false
                                    }
                                }
                            }
                        }
                }
                
                Section(header: Text("Bildirim Türleri")) {
                    Toggle("Partner İstekleri", isOn: $partnerRequestsEnabled)
                        .disabled(!notificationsEnabled)
                    
                    Toggle("Partner Aktiviteleri", isOn: $partnerActivitiesEnabled)
                        .disabled(!notificationsEnabled)
                    
                    Toggle("Hedef Güncellemeleri", isOn: $goalUpdatesEnabled)
                        .disabled(!notificationsEnabled)
                    
                    Toggle("Okuma Serisi Güncellemeleri", isOn: $streakUpdatesEnabled)
                        .disabled(!notificationsEnabled)
                    
                    Toggle("Kilometre Taşları", isOn: $milestonesEnabled)
                        .disabled(!notificationsEnabled)
                    
                    Toggle("Günlük Okuma Hatırlatıcıları", isOn: $dailyRemindersEnabled)
                        .disabled(!notificationsEnabled)
                    
                    if dailyRemindersEnabled {
                        DatePicker("Hatırlatıcı Zamanı", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                    
                    Toggle("Kitap Önerileri", isOn: $recommendationsEnabled)
                        .disabled(!notificationsEnabled)
                    
                    Toggle("Sistem Güncellemeleri", isOn: $systemUpdatesEnabled)
                        .disabled(!notificationsEnabled)
                }
                
                Section(header: Text("Rahatsız Etme Modu")) {
                    Toggle("Rahatsız Etme Modunu Etkinleştir", isOn: .constant(false))
                        .disabled(!notificationsEnabled)
                    
                    DatePicker("Başlangıç", selection: $quietHoursStart, displayedComponents: .hourAndMinute)
                        .disabled(!notificationsEnabled)
                    
                    DatePicker("Bitiş", selection: $quietHoursEnd, displayedComponents: .hourAndMinute)
                        .disabled(!notificationsEnabled)
                }
                
                Section(header: Text("Bildirim Sesi")) {
                    Picker("Ses", selection: $selectedSound) {
                        Text("Varsayılan").tag("default")
                        Text("Hafif").tag("subtle")
                        Text("Sayfa Çevirme").tag("bookPage")
                        Text("Zil").tag("chime")
                        Text("Sessiz").tag("none")
                    }
                    .pickerStyle(MenuPickerStyle())
                    .disabled(!notificationsEnabled)
                }
                
                Section {
                    Button(action: {
                        // Ayarları kaydet
                        saveSettings()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Ayarları Kaydet")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Bildirim Ayarları")
            .navigationBarItems(trailing: Button("Kapat") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    // Ayarları kaydet
    private func saveSettings() {
        // Burada UserDefaults veya Core Data'ya ayarları kaydetme işlemi yapılacak
        // Örneğin:
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        
        // Günlük hatırlatıcı ayarlama
        if dailyRemindersEnabled && notificationsEnabled {
            let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            if let hour = components.hour, let minute = components.minute {
                NotificationService.shared.scheduleDailyReminder(
                    title: "Okuma Zamanı",
                    body: "Bugün okuma hedefine ulaşmak için kitabını açma zamanı geldi!",
                    hour: hour,
                    minute: minute
                )
            }
        }
    }
}

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        let notificationVM = NotificationViewModel()
        let partnerVM = PartnerViewModel()
        
        NotificationsView()
            .environmentObject(notificationVM)
            .environmentObject(partnerVM)
    }
}