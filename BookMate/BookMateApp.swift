import SwiftUI
import CoreData

@main
struct BookMateApp: App {
    // Core Data konfigürasyonu için AppDelegate
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    var body: some Scene {
        WindowGroup {
            AuthenticationView()
                .onAppear {
                    // Core Data'yı başlat
                    _ = CoreDataManager.shared
                }
        }
    }
}

// Core Data konfigürasyonu için AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Uygulama başladığında yapılacak özel işlemler
        print("BookMate uygulaması başlatıldı")
        
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Uygulama kapanırken Core Data bağlamını kaydet
        CoreDataManager.shared.saveContext()
    }
} 