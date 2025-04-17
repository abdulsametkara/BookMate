import SwiftUI

struct BookGridCard: View {
    let book: Book
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                // Cover image
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .aspectRatio(2/3, contentMode: .fit)
                        .cornerRadius(8)
                    
                    if let coverUrl = book.coverImageUrl {
                        AsyncImage(url: coverUrl) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                Image(systemName: "book.closed")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .aspectRatio(2/3, contentMode: .fill)
                        .cornerRadius(8)
                    } else {
                        Image(systemName: "book.closed")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    }
                    
                    // Reading progress indicator
                    if let progress = book.userProgress, progress.readingStatus == .inProgress {
                        VStack {
                            Spacer()
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.black.opacity(0.3))
                                        .frame(height: 8)
                                    
                                    Rectangle()
                                        .fill(Color.blue)
                                        .frame(width: geo.size.width * progress.completionPercentage / 100, height: 8)
                                }
                            }
                            .frame(height: 8)
                        }
                        .cornerRadius(8)
                    }
                    
                    // Status badges
                    if let status = book.userProgress?.readingStatus {
                        VStack {
                            HStack {
                                Spacer()
                                
                                StatusBadge(status: status)
                            }
                            
                            Spacer()
                        }
                        .padding(6)
                    }
                }
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                
                // Book title
                Text(book.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                // Author
                Text(book.authors?.joined(separator: ", ") ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Rating if available
                if let rating = book.userRating, rating > 0 {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= Int(rating) ? "star.fill" : "star")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BookListCard: View {
    let book: Book
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Cover image
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 90)
                        .cornerRadius(6)
                    
                    if let coverUrl = book.coverImageUrl {
                        AsyncImage(url: coverUrl) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                Image(systemName: "book.closed")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: 60, height: 90)
                        .cornerRadius(6)
                    } else {
                        Image(systemName: "book.closed")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    
                    // Status badge
                    if let status = book.userProgress?.readingStatus {
                        VStack {
                            HStack {
                                Spacer()
                                
                                StatusBadge(status: status, isSmall: true)
                            }
                            
                            Spacer()
                        }
                        .padding(4)
                    }
                }
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                VStack(alignment: .leading, spacing: 4) {
                    // Book title
                    Text(book.title)
                        .font(.system(size: 16, weight: .medium))
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    // Author
                    Text(book.authors?.joined(separator: ", ") ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    HStack {
                        // Rating if available
                        if let rating = book.userRating, rating > 0 {
                            HStack(spacing: 2) {
                                ForEach(1...5, id: \.self) { index in
                                    Image(systemName: index <= Int(rating) ? "star.fill" : "star")
                                        .font(.system(size: 10))
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Progress
                        if let progress = book.userProgress, progress.readingStatus == .inProgress {
                            Text("\(Int(progress.completionPercentage))%")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CurrentlyReadingCard: View {
    let book: Book
    var onTap: () -> Void
    var onContinueReading: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 15) {
                // Cover image
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 100, height: 150)
                        .cornerRadius(10)
                    
                    if let coverUrl = book.coverImageUrl {
                        AsyncImage(url: coverUrl) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            case .failure:
                                Image(systemName: "book.closed")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: 100, height: 150)
                        .cornerRadius(10)
                    } else {
                        Image(systemName: "book.closed")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    }
                }
                .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 3)
                
                VStack(alignment: .leading, spacing: 8) {
                    // Title
                    Text(book.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    // Author
                    Text(book.authors?.joined(separator: ", ") ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // Progress
                    if let progress = book.userProgress {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Okunan: \(progress.currentPage)/\(progress.totalPages) sayfa")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("\(Int(progress.completionPercentage))%")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .fontWeight(.medium)
                            }
                            
                            // Progress bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 6)
                                        .cornerRadius(3)
                                    
                                    Rectangle()
                                        .fill(Color.blue)
                                        .frame(width: geo.size.width * progress.completionPercentage / 100, height: 6)
                                        .cornerRadius(3)
                                }
                            }
                            .frame(height: 6)
                        }
                    }
                    
                    // Last read time
                    if let lastRead = book.userProgress?.lastReadAt {
                        Text("Son okuma: \(lastRead, formatter: dateFormatter)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Continue reading button
            Button(action: onContinueReading) {
                Text("Okumaya Devam Et")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .onTapGesture {
            onTap()
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}

struct StatusBadge: View {
    let status: ReadingStatus
    var isSmall: Bool = false
    
    var statusColor: Color {
        switch status {
        case .inProgress:
            return .blue
        case .finished:
            return .green
        case .notStarted:
            return .gray
        case .onHold:
            return .orange
        case .abandoned:
            return .red
        }
    }
    
    var statusIcon: String {
        switch status {
        case .inProgress:
            return "book.fill"
        case .finished:
            return "checkmark"
        case .notStarted:
            return "book.closed"
        case .onHold:
            return "pause.fill"
        case .abandoned:
            return "xmark"
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .font(.system(size: isSmall ? 8 : 10))
                .foregroundColor(.white)
            
            if !isSmall {
                Text(status.description)
                    .font(.system(size: 10))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, isSmall ? 4 : 6)
        .padding(.vertical, isSmall ? 2 : 4)
        .background(statusColor)
        .cornerRadius(isSmall ? 4 : 6)
    }
}

#Preview {
    let sampleBook = Book(
        id: "1",
        isbn: "123456789",
        title: "1984",
        authors: ["George Orwell"],
        publishedDate: "1949",
        description: "A dystopian novel set in a totalitarian regime.",
        pageCount: 328,
        categories: ["Fiction", "Dystopian"],
        language: "en",
        coverImageUrl: URL(string: "https://example.com/cover.jpg"),
        userProgress: ReadingProgress(
            currentPage: 200,
            totalPages: 328,
            startedAt: Date().addingTimeInterval(-60 * 60 * 24 * 10),
            lastReadAt: Date().addingTimeInterval(-60 * 60 * 3),
            completedAt: nil,
            readingStatus: .inProgress,
            minutesRead: 320
        ),
        userRating: 4.5,
        isFavorite: true,
        dateAdded: Date().addingTimeInterval(-60 * 60 * 24 * 15)
    )
    
    return VStack(spacing: 20) {
        BookGridCard(book: sampleBook, onTap: {})
            .frame(width: 160)
        
        BookListCard(book: sampleBook, onTap: {})
            .frame(maxWidth: 400)
        
        CurrentlyReadingCard(book: sampleBook, onTap: {}, onContinueReading: {})
            .frame(maxWidth: 400)
    }
    .padding()
    .background(Color(.systemGray6))
} 