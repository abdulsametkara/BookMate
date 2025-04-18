import SwiftUI

struct ContentView: View {
    @EnvironmentObject var bookViewModel: BookViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    
    var body: some View {
        TabView {
            HomeView()
                .environmentObject(bookViewModel)
                .environmentObject(userViewModel)
                .tabItem {
                    Label("Ana Sayfa", systemImage: "house")
                }
            
            LibraryView()
                .environmentObject(bookViewModel)
                .environmentObject(userViewModel)
                .tabItem {
                    Label("Kütüphane", systemImage: "books.vertical")
                }
            
            StatsView()
                .environmentObject(bookViewModel)
                .environmentObject(userViewModel)
                .tabItem {
                    Label("İstatistikler", systemImage: "chart.bar")
                }
            
            ProfileView()
                .environmentObject(bookViewModel)
                .environmentObject(userViewModel)
                .tabItem {
                    Label("Profil", systemImage: "person")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(BookViewModel())
            .environmentObject(UserViewModel())
    }
} 