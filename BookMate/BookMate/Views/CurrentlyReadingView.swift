import SwiftUI

// Şu anda okunmakta olan kitaplar için görünüm
struct CurrentlyReadingView: View {
    @EnvironmentObject var bookViewModel: BookViewModel
    @State private var showDeleteAlert = false
    @State private var bookToDelete: GoogleBook?
    @State private var showingProgressSheet = false
    @State private var selectedBook: GoogleBook?
    
    var body: some View {
        List {
            // Simplify the expression by fetching the books first
            let readingBooks = bookViewModel.currentlyReadingBooks
            
            if readingBooks.isEmpty {
                Text("Şu anda okumakta olduğunuz kitap bulunmamaktadır.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .listRowBackground(Color.clear)
            } else {
                ForEach(readingBooks) { book in
                    bookRow(for: book)
                }
            }
        }
        .navigationTitle("Okumakta Olduğum Kitaplar")
        .alert("Kitabı Sil", isPresented: $showDeleteAlert) {
            Button("İptal", role: .cancel) { 
                bookToDelete = nil
            }
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
        .sheet(isPresented: $showingProgressSheet) {
            if let book = selectedBook {
                UpdateProgressView(book: book)
            }
        }
    }
    
    // Break up complex UI into separate function
    private func bookRow(for book: GoogleBook) -> some View {
        NavigationLink(destination: BookDetailView(book: book)) {
            HStack(spacing: 12) {
                // Kitap kapağı
                bookCoverView(for: book)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(book.authors.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    // Handle optional pageCount and currentPage
                    HStack {
                        let currentPage = book.currentPage ?? 0
                        let pageCount = book.pageCount ?? 1
                        
                        ProgressView(value: Double(currentPage), total: Double(pageCount))
                            .progressViewStyle(LinearProgressViewStyle())
                            .frame(height: 8)
                        
                        Text("\(currentPage)/\(pageCount)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .contextMenu {
            Button(action: {
                selectedBook = book
                showingProgressSheet = true
            }) {
                Label("İlerleme Güncelle", systemImage: "book")
            }
            
            Button(role: .destructive, action: {
                bookToDelete = book
                showDeleteAlert = true
            }) {
                Label("Kütüphaneden Sil", systemImage: "trash")
            }
        }
    }
    
    // Extract book cover view to separate function
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
                .frame(width: 60, height: 90)
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

// Kitap ilerleme güncelleme görünümü
struct UpdateProgressView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var bookViewModel: BookViewModel
    
    let book: GoogleBook
    @State private var currentPage: Int
    @State private var isFinished = false
    
    init(book: GoogleBook) {
        self.book = book
        // Safely unwrap the optional currentPage
        self._currentPage = State(initialValue: book.currentPage ?? 0)
        self._isFinished = State(initialValue: book.finishedReading != nil)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Okuma İlerlemesi")) {
                    Text("\(book.title)")
                        .font(.headline)
                    
                    // Safely handle the optional pageCount
                    let pageCount = book.pageCount ?? 1
                    
                    VStack(alignment: .leading) {
                        Text("Sayfa: \(currentPage) / \(pageCount)")
                        
                        Slider(value: Binding(
                            get: { Double(currentPage) },
                            set: { currentPage = Int($0) }
                        ), in: 0...Double(pageCount), step: 1)
                    }
                    
                    Toggle("Kitabı tamamladım", isOn: $isFinished)
                }
            }
            .navigationTitle("İlerleme Güncelle")
            .navigationBarItems(
                leading: Button("İptal") {
                    dismiss()
                },
                trailing: Button("Kaydet") {
                    bookViewModel.updateProgress(for: book, newPage: currentPage, completed: isFinished)
                    dismiss()
                }
            )
        }
    }
}

#Preview {
    NavigationView {
        CurrentlyReadingView()
            .environmentObject(BookViewModel())
    }
} 