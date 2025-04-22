import SwiftUI

struct BookCardView: View {
    let book: GoogleBook
    var compact: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Kitap Kapağı
            BookCoverView(imageURL: book.thumbnailURL, size: compact ? 65 : 80)
            
            // Kitap Bilgileri
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(compact ? .headline : .title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(book.authorsText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                if !compact {
                    // Okuma Durumu ve İlerleme
                    if book.readingStatus == .inProgress {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Okuyorsun - %\(Int(book.readingProgressPercentage)) tamamlandı")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            ProgressView(value: book.readingProgressPercentage, total: 100)
                                .progressViewStyle(LinearProgressViewStyle(tint: Color.blue))
                                .frame(height: 5)
                        }
                        .padding(.top, 2)
                    } else if book.readingStatus == .finished {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            
                            Text("Tamamlandı")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .padding(.top, 2)
                    }
                }
                
                Spacer()
                
                if !compact {
                    // Ekleme Tarihi - Şimdilik sabit değer
                    Text("Kitaplığınızda")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(height: compact ? 80 : 120)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
        )
    }
}

struct BookCoverView: View {
    let imageURL: URL?
    var size: CGFloat = 80
    
    var body: some View {
        ZStack {
            // Arkaplan
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: size * 0.7, height: size)
                .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 2)
            
            // Kitap Kapağı
            if let url = imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Image(systemName: "book.closed.fill")
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: size * 0.7, height: size)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: size / 3))
                    .foregroundColor(.gray)
            }
        }
    }
}

struct BookCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            BookCardView(book: GoogleBook(
                id: UUID(),
                isbn: "12345678",
                title: "Sherlock Holmes'un Maceraları",
                authors: ["Arthur Conan Doyle"],
                description: "Ünlü dedektif Sherlock Holmes'un farklı maceraları.",
                pageCount: 320,
                categories: ["Polisiye", "Macera"],
                imageLinks: nil,
                publishedDate: "1892",
                publisher: "Everest Yayınları",
                language: "tr",
                readingStatus: .inProgress,
                readingProgressPercentage: 65
            ))
            
            BookCardView(book: GoogleBook(
                id: UUID(),
                isbn: "98765432",
                title: "Yüzüklerin Efendisi: Yüzük Kardeşliği",
                authors: ["J.R.R. Tolkien"],
                description: "Frodo'nun yüzüğü yok etme görevi.",
                pageCount: 423,
                categories: ["Fantastik", "Macera"],
                imageLinks: nil,
                publishedDate: "1954",
                publisher: "İthaki Yayınları",
                language: "tr",
                readingStatus: .finished,
                readingProgressPercentage: 100
            ))
            
            BookCardView(book: GoogleBook(
                id: UUID(),
                isbn: "45678123",
                title: "Küçük Prens",
                authors: ["Antoine de Saint-Exupéry"],
                description: "Küçük Prens'in gezegen gezegen yolculuğu.",
                pageCount: 96,
                categories: ["Çocuk", "Felsefi"],
                imageLinks: nil,
                publishedDate: "1943",
                publisher: "Can Yayınları",
                language: "tr",
                readingStatus: .notStarted,
                readingProgressPercentage: 0
            ), compact: true)
        }
        .padding()
        .background(Color(.systemGray6))
    }
} 