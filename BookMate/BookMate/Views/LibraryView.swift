import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var bookViewModel: BookViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Tamamlanan kitaplar için hızlı erişim
                    if !bookViewModel.completedBooks.isEmpty {
                        NavigationLink(destination: CompletedBooksView()) {
                            HStack {
                                Text("Tamamlanan Kitaplar (\(bookViewModel.completedBooks.count))")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.blue)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Kütüphanedeki tüm kitaplar
                    ForEach(bookViewModel.userLibrary) { book in
                        LibraryBookItem(book: book)
                    }
                }
                .padding()
            }
            .navigationBarTitle("Kütüphane", displayMode: .inline)
        }
    }
}

struct LibraryBookItem: View {
    let book: Book
    @EnvironmentObject var bookViewModel: BookViewModel
    
    var body: some View {
        NavigationLink(destination: BookDetailView(book: book)) {
            HStack(spacing: 12) {
                // Kitap kapağı
                bookCoverView(for: book)
                    .frame(width: 80, height: 120)
                
                // Kitap bilgileri
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(book.authorsText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer(minLength: 4)
                    
                    // Okuma durumu etiketi - tıklanabilir
                    statusTag
                }
                
                Spacer()
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            // Okuma durumunu hızlıca değiştirmek için context menu
            Button(action: {
                bookViewModel.updateBookStatus(book, status: .notStarted)
            }) {
                Label("Başlanmadı", systemImage: "book.closed")
            }
            
            Button(action: {
                bookViewModel.updateBookStatus(book, status: .inProgress)
            }) {
                Label("Okunuyor", systemImage: "book")
            }
            
            Button(action: {
                bookViewModel.updateBookStatus(book, status: .finished)
            }) {
                Label("Tamamlandı", systemImage: "book.fill")
            }
        }
    }
    
    // Okuma durumu etiketi - "Okundu" tıklandığında okunan kitaplar listesine gider
    private var statusTag: some View {
        Group {
            if book.readingStatus == .finished {
                NavigationLink(destination: CompletedBooksView()) {
                    Text(book.readingStatus.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.1))
                        .foregroundColor(statusColor)
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Text(book.readingStatus.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .foregroundColor(statusColor)
                    .cornerRadius(12)
            }
        }
    }
    
    // İyileştirilmiş kitap kapağı görünümü
    private func bookCoverView(for book: Book) -> some View {
        Group {
            if let url = book.thumbnailURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 80, height: 120)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .failure:
                        bookPlaceholder
                    @unknown default:
                        bookPlaceholder
                    }
                }
            } else {
                bookPlaceholder
            }
        }
    }
    
    private var bookPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .frame(width: 80, height: 120)
            .overlay(
                VStack(spacing: 4) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                    
                    Text(book.title)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                }
            )
    }
    
    private var statusColor: Color {
        switch book.readingStatus {
        case .notStarted:
            return .gray
        case .inProgress:
            return .blue
        case .finished:
            return .green
        }
    }
}

// Tamamlanan kitaplar için yeni görünüm
struct CompletedBooksView: View {
    @EnvironmentObject var bookViewModel: BookViewModel
    
    var body: some View {
        List {
            ForEach(bookViewModel.completedBooks) { book in
                NavigationLink(destination: BookDetailView(book: book)) {
                    HStack(spacing: 12) {
                        // Kitap kapağı
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
                            .frame(width: 60, height: 90)
                        } else {
                            bookCoverPlaceholder(for: book)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(book.title)
                                .font(.headline)
                                .lineLimit(1)
                            
                            Text(book.authors.joined(separator: ", "))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                            
                            // Tamamlanma bilgisi
                            if let finishedDate = book.finishedReading {
                                Text("Tamamlandı: \(formatDate(finishedDate))")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
        }
        .navigationBarTitle("Okuduğum Kitaplar", displayMode: .inline)
    }
    
    private func bookCoverPlaceholder(for book: Book) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .frame(width: 60, height: 90)
            .overlay(
                Image(systemName: "book.closed")
                    .foregroundColor(.gray)
            )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
}

#Preview {
    LibraryView()
        .environmentObject(BookViewModel())
} 