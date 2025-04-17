import SwiftUI

// MARK: - EmptyStateView 
struct EmptyStateView: View {
    let title: String
    let message: String
    let icon: String
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 70))
                .foregroundColor(.gray)
            
            Text(title)
                .font(.title3)
                .bold()
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if let buttonTitle = buttonTitle, let action = action {
                Button(action: action) {
                    Text(buttonTitle)
                        .font(.headline)
                        .padding()
                        .background(AppColors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - LoadingStateView
struct LoadingStateView: View {
    var message: String = "Yükleniyor..."
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - ErrorView
struct ErrorView: View {
    let errorMessage: String
    var retryAction: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Bir hata oluştu")
                .font(.title3)
                .bold()
            
            Text(errorMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if let retryAction = retryAction {
                Button(action: retryAction) {
                    Text("Tekrar Dene")
                        .font(.headline)
                        .padding()
                        .background(AppColors.primary)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - BookCoverView
struct BookCoverView: View {
    let coverUrl: URL?
    var width: CGFloat = 100
    var height: CGFloat = 150
    var cornerRadius: CGFloat = 8
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.gray.opacity(0.2))
                .frame(width: width, height: height)
            
            if let coverUrl = coverUrl {
                AsyncImage(url: coverUrl) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: width, height: height)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: width, height: height)
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    case .failure:
                        defaultCoverImage
                    @unknown default:
                        defaultCoverImage
                    }
                }
            } else {
                defaultCoverImage
            }
        }
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var defaultCoverImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.gray.opacity(0.2))
                .frame(width: width, height: height)
            
            Image(systemName: "book.closed")
                .resizable()
                .scaledToFit()
                .frame(width: width * 0.4)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - AvatarView
struct AvatarView: View {
    let imageUrl: URL?
    var placeholder: String = "person.crop.circle"
    var size: CGFloat = 40
    var showBorder: Bool = false
    var borderColor: Color = .blue
    
    var body: some View {
        if let imageUrl = imageUrl {
            AsyncImage(url: imageUrl) { phase in
                switch phase {
                case .empty:
                    placeholderView
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                        .overlay(borderOverlay)
                case .failure:
                    placeholderView
                @unknown default:
                    placeholderView
                }
            }
        } else {
            placeholderView
        }
    }
    
    private var placeholderView: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: size, height: size)
            
            Image(systemName: placeholder)
                .font(.system(size: size * 0.5))
                .foregroundColor(.gray)
        }
        .overlay(borderOverlay)
    }
    
    private var borderOverlay: some View {
        Circle()
            .stroke(showBorder ? borderColor : Color.clear, lineWidth: showBorder ? 2 : 0)
    }
}

// MARK: - ActionButton
struct ActionButton: View {
    let title: String
    let action: () -> Void
    var icon: String? = nil
    var style: ButtonStyle = .primary
    var width: CGFloat? = nil
    var height: CGFloat = 44
    var isDisabled: Bool = false
    
    enum ButtonStyle {
        case primary, secondary, destructive, outline
        
        var backgroundColor: Color {
            switch self {
            case .primary:
                return AppColors.primary
            case .secondary:
                return Color.clear
            case .destructive:
                return Color.red
            case .outline:
                return Color.clear
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary:
                return .white
            case .secondary:
                return AppColors.primary
            case .destructive:
                return .white
            case .outline:
                return .primary
            }
        }
        
        var borderColor: Color? {
            switch self {
            case .outline:
                return Color.gray.opacity(0.3)
            case .secondary:
                return AppColors.primary
            default:
                return nil
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                }
                
                Text(title)
                    .font(.headline)
            }
            .frame(width: width, height: height)
            .padding(.horizontal, 16)
            .background(isDisabled ? Color.gray.opacity(0.2) : style.backgroundColor)
            .foregroundColor(isDisabled ? Color.gray : style.foregroundColor)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isDisabled ? Color.clear : (style.borderColor ?? Color.clear), lineWidth: style.borderColor != nil ? 1 : 0)
            )
        }
        .disabled(isDisabled)
    }
}

// MARK: - BookStatView
struct BookStatView: View {
    let title: String
    let value: String
    let icon: String
    var iconColor: Color = AppColors.primary
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
        }
        .frame(minWidth: 70)
    }
}

// MARK: - ReadingProgressBar
struct ReadingProgressBar: View {
    let progress: Double
    var showPercentage: Bool = true
    var height: CGFloat = 8
    var color: Color = AppColors.primary
    
    var body: some View {
        VStack(spacing: 2) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: height)
                        .cornerRadius(height / 2)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: max(height, geo.size.width * min(max(progress, 0), 1)), height: height)
                        .cornerRadius(height / 2)
                }
            }
            .frame(height: height)
            
            if showPercentage {
                HStack {
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - RatingView
struct RatingView: View {
    let rating: Double
    var iconSize: CGFloat = 14
    var spacing: CGFloat = 2
    var maxRating: Int = 5
    var color: Color = .yellow
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: index <= Int(rating) ? "star.fill" : (index - Double(Int(rating)) <= rating - Double(Int(rating)) && index - 1 < rating ? "star.leadinghalf.fill" : "star"))
                    .font(.system(size: iconSize))
                    .foregroundColor(color)
            }
            
            if rating > 0 {
                Text("(\(String(format: "%.1f", rating)))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preview
struct ReusableViews_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                Group {
                    EmptyStateView(
                        title: "Henüz kitap yok",
                        message: "Kitaplığınıza kitap eklemek için aşağıdaki düğmeyi kullanın",
                        icon: "book",
                        buttonTitle: "Kitap Ekle",
                        action: {}
                    )
                    .frame(height: 300)
                    
                    LoadingStateView()
                        .frame(height: 100)
                    
                    ErrorView(
                        errorMessage: "Kitaplar yüklenirken bir sorun oluştu. Lütfen internet bağlantınızı kontrol edin.",
                        retryAction: {}
                    )
                    .frame(height: 200)
                }
                
                Group {
                    HStack(spacing: 20) {
                        BookCoverView(coverUrl: nil)
                        
                        BookCoverView(
                            coverUrl: URL(string: "https://example.com/book.jpg"),
                            width: 80,
                            height: 120,
                            cornerRadius: 4
                        )
                    }
                    
                    HStack(spacing: 20) {
                        AvatarView(imageUrl: nil)
                        
                        AvatarView(
                            imageUrl: URL(string: "https://example.com/avatar.jpg"),
                            size: 60,
                            showBorder: true
                        )
                    }
                }
                
                Group {
                    HStack(spacing: 10) {
                        ActionButton(title: "Kaydet", action: {})
                        
                        ActionButton(
                            title: "Sil",
                            action: {},
                            icon: "trash",
                            style: .destructive
                        )
                        
                        ActionButton(
                            title: "İptal",
                            action: {},
                            style: .outline
                        )
                    }
                    
                    HStack(spacing: 10) {
                        BookStatView(
                            title: "Sayfa",
                            value: "328",
                            icon: "doc.text"
                        )
                        
                        BookStatView(
                            title: "Tür",
                            value: "Bilim Kurgu",
                            icon: "tag",
                            iconColor: .purple
                        )
                        
                        BookStatView(
                            title: "Yıl",
                            value: "2020",
                            icon: "calendar",
                            iconColor: .orange
                        )
                    }
                }
                
                Group {
                    ReadingProgressBar(progress: 0.65)
                        .frame(height: 30)
                    
                    RatingView(rating: 3.5)
                }
            }
            .padding()
        }
    }
} 