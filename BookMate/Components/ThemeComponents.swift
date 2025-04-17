import SwiftUI

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Codable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    case warmLight = "warm_light"
    case nightBlue = "night_blue"
    
    var displayName: String {
        switch self {
        case .system:
            return "Sistem"
        case .light:
            return "Açık"
        case .dark:
            return "Koyu"
        case .warmLight:
            return "Sıcak Açık"
        case .nightBlue:
            return "Gece Mavisi"
        }
    }
    
    var icon: String {
        switch self {
        case .system:
            return "iphone"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        case .warmLight:
            return "sunrise.fill"
        case .nightBlue:
            return "moon.stars.fill"
        }
    }
}

// MARK: - Colors

struct AppColors {
    // Primary brand colors
    static let primary = Color("PrimaryColor", bundle: nil)
    static let secondary = Color("SecondaryColor", bundle: nil)
    static let accent = Color("AccentColor", bundle: nil)
    
    // Status colors
    static let success = Color("SuccessColor", bundle: nil)
    static let warning = Color("WarningColor", bundle: nil)
    static let error = Color("ErrorColor", bundle: nil)
    static let info = Color("InfoColor", bundle: nil)
    
    // Book status colors
    static let reading = Color.blue
    static let completed = Color.green
    static let notStarted = Color.gray
    static let onHold = Color.orange
    static let abandoned = Color.red
    
    // Background colors
    static let background = Color("BackgroundColor", bundle: nil)
    static let secondaryBackground = Color("SecondaryBackgroundColor", bundle: nil)
    static let groupedBackground = Color("GroupedBackgroundColor", bundle: nil)
    
    // Text colors
    static let text = Color("TextColor", bundle: nil)
    static let secondaryText = Color("SecondaryTextColor", bundle: nil)
    static let tertiaryText = Color("TertiaryTextColor", bundle: nil)
    
    // Other UI colors
    static let separator = Color("SeparatorColor", bundle: nil)
    static let shadow = Color("ShadowColor", bundle: nil)
    
    // Standard system colors (for fallback)
    static let systemGray = Color(.systemGray)
    static let systemGray2 = Color(.systemGray2)
    static let systemGray3 = Color(.systemGray3)
    static let systemGray4 = Color(.systemGray4)
    static let systemGray5 = Color(.systemGray5)
    static let systemGray6 = Color(.systemGray6)
}

// MARK: - Typography

struct AppFonts {
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title = Font.title.weight(.bold)
    static let title2 = Font.title2.weight(.bold)
    static let title3 = Font.title3.weight(.semibold)
    static let headline = Font.headline
    static let subheadline = Font.subheadline
    static let body = Font.body
    static let callout = Font.callout
    static let caption = Font.caption
    static let caption2 = Font.caption2
    
    static let bookTitle = Font.headline.weight(.medium)
    static let bookAuthor = Font.subheadline
    static let bookCategory = Font.caption.weight(.medium)
    static let buttonLabel = Font.subheadline.weight(.medium)
}

// MARK: - Themed Components

struct ThemedCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 12
    var shadowRadius: CGFloat = 5
    var backgroundColor: Color = AppColors.background
    
    init(padding: CGFloat = 16, 
         cornerRadius: CGFloat = 12, 
         shadowRadius: CGFloat = 5,
         backgroundColor: Color = AppColors.background,
         @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.backgroundColor = backgroundColor
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: AppColors.shadow.opacity(0.1), radius: shadowRadius, x: 0, y: 2)
    }
}

struct ThemedButton: View {
    let title: String
    let action: () -> Void
    var icon: String? = nil
    var buttonStyle: ButtonType = .primary
    var isDisabled: Bool = false
    var width: CGFloat? = nil
    
    enum ButtonType {
        case primary
        case secondary
        case destructive
        case plain
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(title)
                    .font(AppFonts.buttonLabel)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .frame(width: width)
            .background(backgroundForStyle)
            .foregroundColor(foregroundForStyle)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(buttonStyle == .secondary ? AppColors.primary : Color.clear, lineWidth: 2)
            )
            .opacity(isDisabled ? 0.6 : 1)
        }
        .disabled(isDisabled)
    }
    
    private var backgroundForStyle: Color {
        if isDisabled {
            return Color.gray.opacity(0.2)
        }
        
        switch buttonStyle {
        case .primary:
            return AppColors.primary
        case .secondary:
            return Color.clear
        case .destructive:
            return AppColors.error
        case .plain:
            return Color.clear
        }
    }
    
    private var foregroundForStyle: Color {
        if isDisabled {
            return Color.gray
        }
        
        switch buttonStyle {
        case .primary:
            return .white
        case .secondary:
            return AppColors.primary
        case .destructive:
            return .white
        case .plain:
            return AppColors.primary
        }
    }
}

struct ThemedDivider: View {
    var color: Color = AppColors.separator
    var height: CGFloat = 1
    var horizontalPadding: CGFloat = 0
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: height)
            .padding(.horizontal, horizontalPadding)
    }
}

struct ThemedProgressBar: View {
    var progress: Double
    var color: Color = AppColors.primary
    var height: CGFloat = 8
    var showPercentage: Bool = false
    
    var body: some View {
        VStack(spacing: 4) {
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
                Text("\(Int(progress * 100))%")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.secondaryText)
            }
        }
    }
}

struct ThemedHeader: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    var alignment: HorizontalAlignment = .leading
    
    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppColors.primary)
                }
                
                Text(title)
                    .font(AppFonts.title3)
                    .foregroundColor(AppColors.text)
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.secondaryText)
            }
        }
    }
}

struct ThemedSegmentedControl<SelectionValue: Hashable>: View {
    @Binding var selection: SelectionValue
    let values: [SelectionValue]
    let labels: [SelectionValue: String]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(values, id: \.self) { value in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = value
                    }
                }) {
                    Text(labels[value] ?? "")
                        .font(AppFonts.buttonLabel)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                }
                .background(selection == value ? AppColors.primary : Color.clear)
                .foregroundColor(selection == value ? .white : AppColors.primary)
            }
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppColors.primary, lineWidth: 1)
        )
    }
}

struct ThemeColorCircle: View {
    let color: Color
    var isSelected: Bool = false
    var size: CGFloat = 24
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: size, height: size)
            
            if isSelected {
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: size - 4, height: size - 4)
                
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.5))
                    .foregroundColor(.white)
            }
        }
    }
}

struct ThemedEmptyState: View {
    let title: String
    let message: String
    let icon: String
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundColor(AppColors.secondaryText)
            
            Text(title)
                .font(AppFonts.title3)
                .foregroundColor(AppColors.text)
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if let buttonTitle = buttonTitle, let action = action {
                ThemedButton(title: buttonTitle, action: action)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    VStack(spacing: 20) {
        ThemedHeader(title: "Kitap Koleksiyonu", subtitle: "14 kitap", icon: "books.vertical")
        
        ThemedCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Öne Çıkan Koleksiyon")
                    .font(AppFonts.headline)
                
                Text("Klasik Edebiyat")
                    .font(AppFonts.title3)
                
                ThemedDivider()
                
                Text("12 kitap · 3 okundu")
                    .font(AppFonts.caption)
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        
        ThemedProgressBar(progress: 0.65, showPercentage: true)
        
        @State var selectedValue = "list"
        
        ThemedSegmentedControl(
            selection: $selectedValue,
            values: ["list", "grid", "shelf"],
            labels: [
                "list": "Liste",
                "grid": "Izgara",
                "shelf": "Raf"
            ]
        )
        .frame(width: 300)
        
        HStack(spacing: 20) {
            ThemedButton(title: "Kaydet", action: {})
            
            ThemedButton(
                title: "Vazgeç",
                action: {},
                buttonStyle: .secondary
            )
            
            ThemedButton(
                title: "Sil",
                action: {},
                icon: "trash",
                buttonStyle: .destructive
            )
        }
        
        HStack(spacing: 16) {
            ThemeColorCircle(color: .blue, isSelected: true)
            ThemeColorCircle(color: .green)
            ThemeColorCircle(color: .orange)
            ThemeColorCircle(color: .purple)
            ThemeColorCircle(color: .pink)
        }
    }
    .padding()
} 