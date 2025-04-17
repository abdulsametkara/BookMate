import SwiftUI

struct CustomTabView<Content: View>: View {
    @Binding var selectedTab: Int
    let tabs: [TabItem]
    @ViewBuilder let content: (Int) -> Content
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            content(selectedTab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .edgesIgnoringSafeArea(.bottom)
            
            // Custom tab bar
            CustomTabBar(
                selectedTab: $selectedTab,
                tabs: tabs
            )
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [TabItem]
    @State private var bounceValues: [Bool] = Array(repeating: false, count: 5)
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { index in
                let tab = tabs[index]
                TabButton(
                    tab: tab,
                    isSelected: selectedTab == index,
                    hasBadge: tab.badgeValue != nil,
                    bounce: bounceValues[safe: index] ?? false,
                    onTap: {
                        withAnimation {
                            selectedTab = index
                            if let feedback = tab.feedbackStyle {
                                UIImpactFeedbackGenerator(style: feedback).impactOccurred()
                            }
                            animateButton(at: index)
                        }
                    }
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.bottom)
                .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: -1)
        )
    }
    
    private func animateButton(at index: Int) {
        guard index < bounceValues.count else { return }
        
        // Reset any existing animations
        bounceValues[index] = false
        
        // Trigger animation after a small delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.interpolatingSpring(stiffness: 180, damping: 15)) {
                bounceValues[index] = true
                
                // Reset after animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        bounceValues[index] = false
                    }
                }
            }
        }
    }
}

struct TabButton: View {
    let tab: TabItem
    let isSelected: Bool
    let hasBadge: Bool
    let bounce: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                        .font(.system(size: 22))
                        .scaleEffect(bounce ? 1.2 : 1.0)
                    
                    if hasBadge {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .offset(x: 10, y: -10)
                    }
                }
                
                Text(tab.title)
                    .font(.system(size: 11))
                    .fontWeight(isSelected ? .medium : .regular)
            }
            .foregroundColor(isSelected ? AppColors.primary : Color.gray)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TabItem {
    let title: String
    let icon: String
    let selectedIcon: String
    var badgeValue: Int? = nil
    var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle? = .light
}

// Extension to safely access array elements
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview
struct CustomTabView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewTabView()
    }
    
    struct PreviewTabView: View {
        @State private var selectedTab = 0
        
        let tabs = [
            TabItem(title: "Ana Sayfa", icon: "house", selectedIcon: "house.fill"),
            TabItem(title: "Kütüphane", icon: "books.vertical", selectedIcon: "books.vertical.fill"),
            TabItem(title: "Ara", icon: "magnifyingglass", selectedIcon: "magnifyingglass"),
            TabItem(title: "Aktivite", icon: "bell", selectedIcon: "bell.fill", badgeValue: 3),
            TabItem(title: "Profil", icon: "person", selectedIcon: "person.fill")
        ]
        
        var body: some View {
            CustomTabView(selectedTab: $selectedTab, tabs: tabs) { index in
                switch index {
                case 0:
                    Color.blue.opacity(0.2)
                        .overlay(Text("Ana Sayfa").font(.largeTitle))
                case 1:
                    Color.green.opacity(0.2)
                        .overlay(Text("Kütüphane").font(.largeTitle))
                case 2:
                    Color.orange.opacity(0.2)
                        .overlay(Text("Ara").font(.largeTitle))
                case 3:
                    Color.purple.opacity(0.2)
                        .overlay(Text("Aktivite").font(.largeTitle))
                case 4:
                    Color.pink.opacity(0.2)
                        .overlay(Text("Profil").font(.largeTitle))
                default:
                    EmptyView()
                }
            }
        }
    }
} 