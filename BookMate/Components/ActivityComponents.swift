import SwiftUI

struct ActivityFeedItem: View {
    let activity: ReadingActivity
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            HStack(spacing: 12) {
                // Book cover or user avatar
                ZStack {
                    if let coverUrl = activity.coverImageUrl {
                        AsyncImage(url: coverUrl) { phase in
                            switch phase {
                            case .empty:
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 50, height: 70)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 70)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            case .failure:
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 50, height: 70)
                                    .overlay(
                                        Image(systemName: "book.closed")
                                            .foregroundColor(.gray)
                                    )
                            @unknown default:
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 50, height: 70)
                            }
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 50, height: 70)
                            .overlay(
                                Image(systemName: "book.closed")
                                    .foregroundColor(.gray)
                            )
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // Activity title with username
                    Text(activity.username)
                        .font(.subheadline)
                        .fontWeight(.medium) +
                    Text(" \(activity.description)")
                        .font(.subheadline)
                    
                    // Book title if activity relates to a book
                    if !activity.bookTitle.isEmpty {
                        Text(activity.bookTitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Timestamp
                    Text(activity.timestamp, formatter: dateFormatter)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Activity type icon
                Circle()
                    .fill(activityColor)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: activityIcon)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    )
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Activity color based on type
    private var activityColor: Color {
        switch activity.activityType {
        case .startedReading:
            return .blue
        case .finishedReading:
            return .green
        case .updatedProgress:
            return .orange
        case .addedToLibrary:
            return .purple
        case .pausedReading:
            return .yellow
        case .abandonedBook:
            return .red
        case .addedNote:
            return .indigo
        case .sharedBook:
            return .pink
        }
    }
    
    // Activity icon based on type
    private var activityIcon: String {
        switch activity.activityType {
        case .startedReading:
            return "book"
        case .finishedReading:
            return "checkmark"
        case .updatedProgress:
            return "chart.bar.fill"
        case .addedToLibrary:
            return "plus"
        case .pausedReading:
            return "pause"
        case .abandonedBook:
            return "xmark"
        case .addedNote:
            return "note.text"
        case .sharedBook:
            return "person.2"
        }
    }
    
    // Date formatter for timestamp
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }
}

struct PartnerNotificationItem: View {
    let notification: ActivityNotification
    var onAccept: (() -> Void)? = nil
    var onDismiss: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Partner avatar
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    // Notification title
                    Text("\(notification.senderUsername) \(notificationTitle)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    // Timestamp
                    Text(notification.timestamp, formatter: dateFormatter)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Activity type icon
                Circle()
                    .fill(notificationColor)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: notificationIcon)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    )
            }
            
            // Message if present
            if !notification.message.isEmpty {
                Text(notification.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            // Action buttons if necessary
            if notification.type == .partnerRequest || notification.type == .bookShareRequest {
                HStack(spacing: 12) {
                    Button(action: {
                        onDismiss?()
                    }) {
                        Text("Reddet")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        onAccept?()
                    }) {
                        Text("Kabul Et")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding(.top, 4)
            } else {
                Button(action: {
                    onDismiss?()
                }) {
                    Text("Tamam")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(8)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // Notification title based on type
    private var notificationTitle: String {
        switch notification.type {
        case .partnerRequest:
            return "eşleşme isteği gönderdi"
        case .partnerAccepted:
            return "eşleşme isteğinizi kabul etti"
        case .bookShareRequest:
            return "bir kitap paylaşmak istiyor"
        case .bookShared:
            return "bir kitap paylaştı"
        case .goalAchieved:
            return "bir okuma hedefine ulaştı"
        case .activityUpdate:
            return "bir aktivite gerçekleştirdi"
        case .bookRecommendation:
            return "size bir kitap önerdi"
        }
    }
    
    // Notification color based on type
    private var notificationColor: Color {
        switch notification.type {
        case .partnerRequest, .partnerAccepted:
            return .blue
        case .bookShareRequest, .bookShared:
            return .green
        case .goalAchieved:
            return .orange
        case .activityUpdate:
            return .purple
        case .bookRecommendation:
            return .pink
        }
    }
    
    // Notification icon based on type
    private var notificationIcon: String {
        switch notification.type {
        case .partnerRequest, .partnerAccepted:
            return "person.2.fill"
        case .bookShareRequest, .bookShared:
            return "book.fill"
        case .goalAchieved:
            return "flag.fill"
        case .activityUpdate:
            return "bell.fill"
        case .bookRecommendation:
            return "star.fill"
        }
    }
    
    // Date formatter for timestamp
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }
}

struct ActivityFeedSection: View {
    let title: String
    let activities: [ReadingActivity]
    var showAll: Bool = true
    var onShowAllTapped: (() -> Void)? = nil
    var onActivityTapped: ((ReadingActivity) -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                if showAll && activities.count > 3 {
                    Button(action: {
                        onShowAllTapped?()
                    }) {
                        Text("Tümünü Gör")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            ForEach(activities.prefix(3), id: \.id) { activity in
                ActivityFeedItem(activity: activity) {
                    onActivityTapped?(activity)
                }
                
                if activity.id != activities.prefix(3).last?.id {
                    Divider()
                }
            }
            
            if activities.isEmpty {
                HStack {
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Image(systemName: "bell.slash")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        
                        Text("Henüz aktivite bulunmuyor")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct NotificationBadge: View {
    let count: Int
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.red)
            
            Text("\(min(count, 99))")
                .font(.system(size: 12))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(4)
        }
        .frame(width: 20, height: 20)
    }
}

// Sample models for preview
struct ActivityNotification: Identifiable {
    var id = UUID().uuidString
    var type: NotificationType
    var senderUserId: String
    var senderUsername: String
    var message: String
    var timestamp: Date
    var isRead: Bool = false
    var relatedBookId: String?
    var relatedBookTitle: String?
    
    enum NotificationType: String, Codable {
        case partnerRequest
        case partnerAccepted
        case bookShareRequest
        case bookShared
        case goalAchieved
        case activityUpdate
        case bookRecommendation
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            let sampleActivity1 = ReadingActivity(
                id: "1",
                userId: "user1",
                username: "Ahmet",
                bookId: "book1",
                bookTitle: "1984",
                coverImageUrl: nil,
                activityType: .startedReading,
                description: "okumaya başladı: 1984",
                timestamp: Date()
            )
            
            let sampleActivity2 = ReadingActivity(
                id: "2",
                userId: "user2",
                username: "Ayşe",
                bookId: "book2",
                bookTitle: "Dönüşüm",
                coverImageUrl: nil,
                activityType: .finishedReading,
                description: "okumayı bitirdi: Dönüşüm",
                timestamp: Date().addingTimeInterval(-60 * 60 * 2)
            )
            
            let sampleActivity3 = ReadingActivity(
                id: "3",
                userId: "user3",
                username: "Mehmet",
                bookId: "book3",
                bookTitle: "Suç ve Ceza",
                coverImageUrl: nil,
                activityType: .updatedProgress,
                description: "%75 ilerledi: Suç ve Ceza",
                timestamp: Date().addingTimeInterval(-60 * 60 * 24)
            )
            
            ActivityFeedItem(activity: sampleActivity1)
            ActivityFeedItem(activity: sampleActivity2)
            ActivityFeedItem(activity: sampleActivity3)
            
            ActivityFeedSection(
                title: "Partner Aktiviteleri",
                activities: [sampleActivity1, sampleActivity2, sampleActivity3]
            )
            
            let partnerRequest = ActivityNotification(
                type: .partnerRequest,
                senderUserId: "user4",
                senderUsername: "Zeynep",
                message: "Birlikte kitap okuyalım!",
                timestamp: Date().addingTimeInterval(-30 * 60)
            )
            
            let bookShare = ActivityNotification(
                type: .bookShareRequest,
                senderUserId: "user2",
                senderUsername: "Ayşe",
                message: "Bu kitabı beğeneceğini düşündüm.",
                timestamp: Date().addingTimeInterval(-3 * 60 * 60),
                relatedBookId: "book4",
                relatedBookTitle: "Hayvan Çiftliği"
            )
            
            PartnerNotificationItem(notification: partnerRequest)
            PartnerNotificationItem(notification: bookShare)
        }
        .padding()
    }
} 