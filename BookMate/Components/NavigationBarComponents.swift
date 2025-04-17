import SwiftUI

struct CustomNavigationBar: View {
    let title: String
    var subtitle: String? = nil
    var leadingButton: NavigationBarButton? = nil
    var trailingButton: NavigationBarButton? = nil
    var secondTrailingButton: NavigationBarButton? = nil
    var backgroundColor: Color = Color(.systemBackground)
    var showsDivider: Bool = true
    var largeTitleDisplayMode: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                // Leading button or space
                if let leadingButton = leadingButton {
                    NavigationBarButtonView(button: leadingButton)
                } else {
                    Spacer()
                        .frame(width: 40)
                }
                
                Spacer()
                
                // Title
                VStack(spacing: 2) {
                    Text(title)
                        .font(largeTitleDisplayMode ? .title2.bold() : .headline)
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Trailing buttons or space
                if let secondTrailingButton = secondTrailingButton {
                    NavigationBarButtonView(button: secondTrailingButton)
                } else {
                    Spacer()
                        .frame(width: 40)
                }
                
                if let trailingButton = trailingButton {
                    NavigationBarButtonView(button: trailingButton)
                } else {
                    Spacer()
                        .frame(width: 40)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .background(backgroundColor)
            
            if showsDivider {
                Divider()
            }
        }
    }
}

struct NavigationBarButton {
    var icon: String? = nil
    var title: String? = nil
    var action: () -> Void
    var disabled: Bool = false
    var showsBadge: Bool = false
    var badgeCount: Int = 0
}

struct NavigationBarButtonView: View {
    let button: NavigationBarButton
    
    var body: some View {
        Button(action: button.action) {
            ZStack(alignment: .topTrailing) {
                if let icon = button.icon {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                } else if let title = button.title {
                    Text(title)
                        .font(.headline)
                        .frame(height: 40)
                        .contentShape(Rectangle())
                }
                
                if button.showsBadge && button.badgeCount > 0 {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 18, height: 18)
                        
                        if button.badgeCount < 100 {
                            Text("\(button.badgeCount)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("99+")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .offset(x: 10, y: -5)
                }
            }
        }
        .disabled(button.disabled)
        .foregroundColor(button.disabled ? .gray : .primary)
    }
}

struct TabBarView: View {
    @Binding var selectedTab: Int
    let items: [TabBarItem]
    var backgroundColor: Color = Color(.systemBackground)
    var activeColor: Color = AppColors.primary
    var inactiveColor: Color = .gray
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { index in
                let item = items[index]
                
                Button(action: {
                    selectedTab = index
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == index ? item.selectedIcon : item.icon)
                            .font(.system(size: 24))
                        
                        Text(item.title)
                            .font(.caption)
                    }
                    .foregroundColor(selectedTab == index ? activeColor : inactiveColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .overlay(
                    ZStack {
                        if item.showsBadge {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 10, height: 10)
                                .offset(x: 12, y: -14)
                        }
                    }, alignment: .topTrailing
                )
            }
        }
        .background(backgroundColor)
        .overlay(
            Divider().padding(.bottom, 49),
            alignment: .top
        )
    }
}

struct TabBarItem {
    let title: String
    let icon: String
    let selectedIcon: String
    var showsBadge: Bool = false
}

struct CustomSectionHeader: View {
    let title: String
    var showViewAll: Bool = false
    var viewAllAction: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            if showViewAll {
                Button(action: {
                    viewAllAction?()
                }) {
                    Text("Tümünü Gör")
                        .font(.subheadline)
                        .foregroundColor(AppColors.primary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}

struct NavigationBarComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CustomNavigationBar(
                title: "Kütüphane",
                leadingButton: NavigationBarButton(
                    icon: "line.3.horizontal", 
                    action: {}
                ),
                trailingButton: NavigationBarButton(
                    icon: "magnifyingglass", 
                    action: {}
                ),
                secondTrailingButton: NavigationBarButton(
                    icon: "bell", 
                    action: {},
                    showsBadge: true,
                    badgeCount: 3
                )
            )
            
            CustomNavigationBar(
                title: "Kitap Detayları",
                subtitle: "George Orwell",
                leadingButton: NavigationBarButton(
                    icon: "chevron.left", 
                    action: {}
                ),
                trailingButton: NavigationBarButton(
                    icon: "ellipsis", 
                    action: {}
                ),
                largeTitleDisplayMode: true
            )
            
            @State var selectedTab = 0
            
            TabBarView(
                selectedTab: $selectedTab,
                items: [
                    TabBarItem(title: "Ana Sayfa", icon: "house", selectedIcon: "house.fill"),
                    TabBarItem(title: "Kütüphane", icon: "books.vertical", selectedIcon: "books.vertical.fill"),
                    TabBarItem(title: "Koleksiyonlar", icon: "folder", selectedIcon: "folder.fill", showsBadge: true),
                    TabBarItem(title: "Profil", icon: "person", selectedIcon: "person.fill")
                ]
            )
            
            CustomSectionHeader(
                title: "Şu Anda Okunanlar",
                showViewAll: true,
                viewAllAction: {}
            )
            
            Spacer()
        }
    }
} 