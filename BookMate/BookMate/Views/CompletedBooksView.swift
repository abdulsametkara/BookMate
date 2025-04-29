import SwiftUI

// Tamamlanan kitaplar için görünüm
struct CompletedBooksView: View {
    @EnvironmentObject var bookViewModel: BookViewModel
    @State private var bookToDelete: GoogleBook? = nil
    @State private var showDeleteAlert = false
    
    var body: some View {
        List {
            // Extract books list to simplify the expression
            let completedBooks = bookViewModel.completedBooks
            
            if completedBooks.isEmpty {
                Text("Henüz tamamlanmış kitabınız bulunmamaktadır.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .listRowBackground(Color.clear)
            } else {
                ForEach(completedBooks) { book in
                    bookRow(for: book)
                }
            }
        }
        .navigationTitle("Okuduğum Kitaplar")
        .alert("Kitabı Sil", isPresented: $showDeleteAlert) {
            Button("İptal", role: .cancel) { bookToDelete = nil }
            
            Button("Sil", role: .destructive) {
                if let book = bookToDelete {
                    withAnimation {
                        bookViewModel.removeFromLibrary(book)
                    }
                }
                bookToDelete = nil
            }
        } message: {
            if let book = bookToDelete {
                Text("\"\(book.title)\" kitabını kütüphanenizden silmek istediğinize emin misiniz?")
            } else {
                Text("Bu kitabı kütüphanenizden silmek istediğinize emin misiniz?")
            }
        }
    }
    
    // Extract book row to a separate function
    private func bookRow(for book: GoogleBook) -> some View {
        NavigationLink(destination: BookDetailView(book: book)) {
            HStack(spacing: 12) {
                // Kitap kapağı
                bookCoverView(for: book)
                    .frame(width: 60, height: 90)
                
                bookInfoView(for: book)
            }
        }
        .contextMenu {
            Button(action: {
                bookToDelete = book
                showDeleteAlert = true
            }) {
                Label("Kütüphaneden Sil", systemImage: "trash")
            }
        }
    }
    
    // Extract book info to a separate function
    private func bookInfoView(for book: GoogleBook) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(book.title)
                .font(.headline)
                .lineLimit(2)
            
            Text(book.authors.joined(separator: ", "))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            if let finishedDate = book.finishedReading {
                Text("Tamamlandı: \(dateFormatter.string(from: finishedDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Extract rating view to simplify
            bookRatingView(rating: book.userRating)
        }
    }
    
    // Extract rating view to a separate function
    private func bookRatingView(rating: Int?) -> some View {
        Group {
            if let rating = rating, rating > 0 {
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= rating ? "star.fill" : "star")
                            .foregroundColor(i <= rating ? .yellow : .gray)
                            .font(.caption)
                    }
                }
            }
        }
    }
    
    // Tamamlanma tarihi için formatter
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter
    }
    
    // Kitap kapağı görünümü
    private func bookCoverView(for book: GoogleBook) -> some View {
        Group {
            if let url = book.thumbnailURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 60, height: 90)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 90)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .failure:
                        bookCoverPlaceholder(for: book)
                    @unknown default:
                        bookCoverPlaceholder(for: book)
                    }
                }
            } else {
                bookCoverPlaceholder(for: book)
            }
        }
    }
    
    // Kitap kapağı placeholder
    private func bookCoverPlaceholder(for book: GoogleBook) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .frame(width: 60, height: 90)
            .overlay(
                VStack(spacing: 4) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                    
                    Text(book.title)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                }
            )
    }
}

#Preview {
    NavigationView {
        CompletedBooksView()
            .environmentObject(BookViewModel())
    }
} 