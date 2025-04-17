import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Ana Sayfa", systemImage: "house")
                }
            
            LibraryView()
                .tabItem {
                    Label("Kütüphane", systemImage: "books.vertical")
                }
            
            StatsView()
                .tabItem {
                    Label("İstatistikler", systemImage: "chart.bar")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 