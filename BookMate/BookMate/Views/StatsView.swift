import SwiftUI

struct StatsView: View {
    @EnvironmentObject var bookViewModel: BookViewModel
    @EnvironmentObject var userViewModel: BookMate.UserViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // İstatistik kartları
                    HStack(spacing: 15) {
                        StatCard(
                            title: "Toplam Kitap",
                            value: "\(userViewModel.currentUser?.statistics?.totalBooksRead ?? 0)",
                            icon: "book.closed",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Bu Yıl",
                            value: "\(userViewModel.currentUser?.statistics?.booksReadThisYear ?? 0)",
                            icon: "calendar",
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                    
                    // Okuma serisi
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Okuma Serisi")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        HStack(spacing: 20) {
                            VStack {
                                Text("\(userViewModel.currentUser?.statistics?.readingStreak ?? 0)")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.orange)
                                
                                Text("Gün")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Şu anki serisi")
                                    .font(.headline)
                                
                                Text("En uzun serisi: \(userViewModel.currentUser?.statistics?.longestStreak ?? 0) gün")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Kitap türleri
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Favori Türler")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(["Roman", "Klasik", "Bilim Kurgu", "Tarih", "Fantastik"], id: \.self) { genre in
                                    VStack(spacing: 10) {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 60, height: 60)
                                            .overlay(
                                                Text(genre.prefix(1))
                                                    .font(.title2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                            )
                                        
                                        Text(genre)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationBarTitle("İstatistikler", displayMode: .inline)
        }
    }
}

struct StatCard: View {
    var title: String
    var value: String
    var icon: String
    var color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 20))
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 30, weight: .bold))
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    let bookVM = BookViewModel()
    let userVM = BookMate.UserViewModel()
    return StatsView()
        .environmentObject(bookVM)
        .environmentObject(userVM)
} 