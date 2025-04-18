import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var bookViewModel: BookViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
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
    
    var body: some View {
        HStack(spacing: 12) {
            // Book cover
            if let url = book.thumbnailURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        bookPlaceholder
                    }
                }
                .frame(width: 80, height: 120)
            } else {
                bookPlaceholder
            }
            
            // Book info
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(book.authorsText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer(minLength: 4)
                
                Text(book.readingStatus.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .foregroundColor(statusColor)
                    .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var bookPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .frame(width: 80, height: 120)
            .overlay(
                Image(systemName: "book.closed")
                    .foregroundColor(.gray)
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

#Preview {
    LibraryView()
        .environmentObject(BookViewModel())
} 