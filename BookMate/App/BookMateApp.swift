import SwiftUI
import Firebase

@main
struct BookMateApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var networkMonitor = NetworkMonitor()
    @StateObject private var userViewModel = UserViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userViewModel)
                .environmentObject(networkMonitor)
                .onAppear {
                    // Uygulama başladığında senkronizasyon dene
                    if networkMonitor.isConnected && userViewModel.isLoggedIn {
                        syncData()
                    }
                }
                .onChange(of: networkMonitor.isConnected) { isConnected in
                    // Ağ bağlantısı geri geldiğinde senkronize et
                    if isConnected && userViewModel.isLoggedIn {
                        syncData()
                    }
                }
        }
    }
    
    // Veri senkronizasyonu
    private func syncData() {
        SyncService.shared.syncAll()
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("Veri senkronizasyonu tamamlandı")
                    case .failure(let error):
                        print("Veri senkronizasyonu hatası: \(error.localizedDescription)")
                    }
                },
                receiveValue: { result in
                    print("Senkronizasyon sonucu: \(result.success ? "Başarılı" : "Başarısız")")
                    print("Son senkronizasyon: \(result.lastSyncDate?.description ?? "Yok")")
                    print("Senkronize edilen öğe sayısı: \(result.syncedItems)")
                    
                    if !result.errors.isEmpty {
                        print("Hatalar:")
                        for error in result.errors {
                            print(" - \(error.localizedDescription)")
                        }
                    }
                }
            )
    }
}

// Uygulama Delegesi
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Firebase yapılandırması
        FirebaseManager.shared // Singleton çağrılarak FirebaseApp'i yapılandırır
        
        // Bildirim izinleri
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        
        return true
    }
    
    // Remote notifikasyon kaydı başarılı
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Cihaz belirteci alındı")
    }
    
    // Remote notifikasyon kaydı başarısız
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Push bildirimleri için kayıt başarısız: \(error.localizedDescription)")
    }
}

// Ağ bağlantısı izleyici
class NetworkMonitor: ObservableObject {
    @Published var isConnected = true
    private let monitor = NWPathMonitor()
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}

// Kullanıcı ViewModel
class UserViewModel: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoggedIn = false
    
    private let firebaseManager = FirebaseManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Otomatik giriş kontrolü
        checkCurrentUser()
    }
    
    func checkCurrentUser() {
        if let userId = firebaseManager.getCurrentUserId() {
            // Oturum açık
            firebaseManager.fetchUserProfile(userId: userId) { [weak self] result in
                switch result {
                case .success(let userData):
                    let user = User(
                        id: userId,
                        name: userData["name"] as? String ?? "",
                        email: userData["email"] as? String ?? ""
                    )
                    
                    DispatchQueue.main.async {
                        self?.currentUser = user
                        self?.isLoggedIn = true
                    }
                    
                case .failure(let error):
                    print("Kullanıcı bilgileri getirilemedi: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self?.isLoggedIn = false
                    }
                }
            }
        } else {
            // Oturum kapalı
            DispatchQueue.main.async {
                self.isLoggedIn = false
                self.currentUser = nil
            }
        }
    }
    
    func login(email: String, password: String) {
        firebaseManager.loginUser(email: email, password: password)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Giriş hatası: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] user in
                    self?.currentUser = user
                    self?.isLoggedIn = true
                }
            )
            .store(in: &cancellables)
    }
    
    func logout() {
        firebaseManager.logoutUser()
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Çıkış hatası: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.currentUser = nil
                    self?.isLoggedIn = false
                }
            )
            .store(in: &cancellables)
    }
} 