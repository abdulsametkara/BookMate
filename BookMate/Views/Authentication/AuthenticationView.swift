import SwiftUI

struct AuthenticationView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainAppView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            // Kimlik doğrulama durumunun kontrolü burada yapılır
            // Bu işlem zaten AuthenticationManager sınıfının init metodunda gerçekleşiyor
        }
    }
}

// Ana uygulama görünümü (ContentView'i sarmalayan bir görünüm)
struct MainAppView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var libraryViewModel = LibraryViewModel()
    @StateObject private var userViewModel = UserViewModel()
    
    var body: some View {
        ContentView()
            .environmentObject(libraryViewModel)
            .environmentObject(userViewModel)
            .onAppear {
                // AuthenticationManager'daki kullanıcıyı UserViewModel'a aktarma
                if let user = authManager.currentUser {
                    userViewModel.currentUser = user
                }
            }
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
} 