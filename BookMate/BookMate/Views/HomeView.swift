import SwiftUI

struct HomeView: View {
    @EnvironmentObject var bookViewModel: BookViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Kullanıcı karşılama
                    Text("Merhaba, \(userViewModel.currentUser?.username ?? "Kullanıcı")")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)
                        .padding(.horizontal)
                    
                    // Şu anda okunanlar
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Şu Anda Okuduklarım")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button("Tümünü Gör") {
                                // Tüm kitapları görüntüle
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        
                        if bookViewModel.currentlyReadingBooks.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "book.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                
                                Text("Şu anda okuduğunuz kitap yok")
                                    .foregroundColor(.secondary)
                                
                                Button("Kitap Ekle") {
                                    // Kitap ekle sayfasına git
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            .frame(height: 180)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(bookViewModel.currentlyReadingBooks) { book in
                                        VStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: 120, height: 180)
                                                .overlay(
                                                    Text(book.title)
                                                        .font(.caption)
                                                        .foregroundColor(.primary)
                                                        .multilineTextAlignment(.center)
                                                        .padding(4)
                                                )
                                            
                                            Text(book.title)
                                                .font(.headline)
                                                .lineLimit(2)
                                                .frame(width: 120)
                                            
                                            Text(book.authors?.first ?? "Bilinmeyen Yazar")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                                .frame(width: 120, alignment: .leading)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Son eklenenler
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Son Eklenenler")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button("Tümünü Gör") {
                                // Tüm kitapları görüntüle
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(bookViewModel.recentlyAddedBooks) { book in
                                    VStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 120, height: 180)
                                            .overlay(
                                                Text(book.title)
                                                    .font(.caption)
                                                    .foregroundColor(.primary)
                                                    .multilineTextAlignment(.center)
                                                    .padding(4)
                                            )
                                        
                                        Text(book.title)
                                            .font(.headline)
                                            .lineLimit(2)
                                            .frame(width: 120)
                                        
                                        Text(book.authors?.first ?? "Bilinmeyen Yazar")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                            .frame(width: 120, alignment: .leading)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationBarTitle("BookMate", displayMode: .inline)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(BookViewModel())
        .environmentObject(UserViewModel())
} 