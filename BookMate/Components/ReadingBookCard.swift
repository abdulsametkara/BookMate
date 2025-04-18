import SwiftUI

struct ReadingBookCard: View {
    var book: Book
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Arkaplan
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
            
            // İçerik
            HStack(spacing: 16) {
                // Kitap kapağı
                if let imageUrl = book.imageLinks?.thumbnailURL {
                    AsyncImage(url: imageUrl) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 120)
                            .cornerRadius(8)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 120)
                            .cornerRadius(8)
                            .overlay(
                                Image(systemName: "book.closed")
                                    .foregroundColor(.gray)
                            )
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 80, height: 120)
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "book.closed")
                                .foregroundColor(.gray)
                        )
                }
                
                // Kitap bilgileri
                VStack(alignment: .leading, spacing: 8) {
                    Text(book.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(book.formattedAuthors)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // İlerleme çubuğu
                    VStack(alignment: .leading, spacing: 4) {
                        ProgressBar(value: book.readingProgressPercentage / 100)
                            .frame(height: 6)
                        
                        HStack {
                            Text("\(book.currentPage)/\(book.pageCount ?? 0) sayfa")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("%\(Int(book.readingProgressPercentage))")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.vertical, 12)
            }
            .padding(.horizontal, 16)
        }
    }
}

struct ReadingBookCard_Previews: PreviewProvider {
    static var previews: some View {
        let sampleBook = Book(
            id: UUID().uuidString,
            isbn: "9780451524935",
            title: "1984",
            authors: ["George Orwell"],
            pageCount: 328,
            currentPage: 156,
            readingStatus: .inProgress
        )
        
        ReadingBookCard(book: sampleBook)
            .frame(width: 280, height: 160)
            .padding()
            .previewLayout(.sizeThatFits)
    }
} 