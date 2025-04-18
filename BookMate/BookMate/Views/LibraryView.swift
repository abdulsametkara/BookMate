import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var bookViewModel: BookViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                    ForEach(bookViewModel.userLibrary) { book in
                        VStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 200)
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
                            
                            Text(book.authors?.first ?? "Bilinmeyen Yazar")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitle("Kütüphane", displayMode: .inline)
        }
    }
}

#Preview {
    LibraryView()
        .environmentObject(BookViewModel())
        .environmentObject(UserViewModel())
} 