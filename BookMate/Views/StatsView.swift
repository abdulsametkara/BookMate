import SwiftUI

struct StatsView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @State private var selectedTimeRange = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Zaman aralığı seçici
                    Picker("Zaman Aralığı", selection: $selectedTimeRange) {
                        Text("Bu Hafta").tag(0)
                        Text("Bu Ay").tag(1)
                        Text("Bu Yıl").tag(2)
                        Text("Tüm Zamanlar").tag(3)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Özet istatistikler
                    HStack(spacing: 15) {
                        StatCardView(
                            title: "Okunan Kitaplar",
                            value: getReadBooksCountForSelectedPeriod(),
                            icon: "book.closed",
                            color: .blue
                        )
                        
                        StatCardView(
                            title: "Okunan Sayfalar",
                            value: getReadPagesCountForSelectedPeriod(),
                            icon: "doc.text",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)
                    
                    HStack(spacing: 15) {
                        StatCardView(
                            title: "Okuma Süresi",
                            value: getReadingTimeForSelectedPeriod(),
                            icon: "clock",
                            color: .purple
                        )
                        
                        StatCardView(
                            title: "Günlük Ortalama",
                            value: "\(userViewModel.currentUser?.statistics.averageDailyReadingTimeMinutes ?? 0) dk",
                            icon: "chart.bar",
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                    
                    // Kategori dağılımı
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tür Dağılımı")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        GenreDistributionChart()
                            .frame(height: 200)
                            .padding()
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Okuma trendleri
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Okuma Trendi")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ReadingTrendChart()
                            .frame(height: 200)
                            .padding()
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Okuma hedefleri
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Hedeflerim")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if let preferences = userViewModel.currentUser?.preferences {
                            ReadingGoalView(
                                title: "Haftalık Kitap",
                                current: userViewModel.currentUser?.statistics.booksReadThisWeek ?? 0,
                                goal: preferences.weeklyBookGoal,
                                unit: "kitap",
                                color: .blue
                            )
                            .padding(.horizontal)
                            
                            ReadingGoalView(
                                title: "Aylık Sayfa",
                                current: userViewModel.currentUser?.statistics.pagesReadThisMonth ?? 0,
                                goal: preferences.monthlyPageGoal,
                                unit: "sayfa",
                                color: .orange
                            )
                            .padding(.horizontal)
                            
                            ReadingGoalView(
                                title: "Yıllık Kitap",
                                current: userViewModel.currentUser?.statistics.booksReadThisYear ?? 0,
                                goal: preferences.yearlyBookGoal,
                                unit: "kitap",
                                color: .green
                            )
                            .padding(.horizontal)
                        } else {
                            ReadingGoalView(
                                title: "Haftalık Kitap",
                                current: 0,
                                goal: 1,
                                unit: "kitap",
                                color: .blue
                            )
                            .padding(.horizontal)
                            
                            ReadingGoalView(
                                title: "Aylık Sayfa",
                                current: 0,
                                goal: 500,
                                unit: "sayfa",
                                color: .orange
                            )
                            .padding(.horizontal)
                            
                            ReadingGoalView(
                                title: "Yıllık Kitap",
                                current: 0,
                                goal: 24,
                                unit: "kitap",
                                color: .green
                            )
                            .padding(.horizontal)
                        }
                        
                        NavigationLink(destination: GoalSettingsView()) {
                            Text("Hedefleri Düzenle")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding()
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("İstatistikler")
            .onAppear {
                userViewModel.loadUser()
            }
        }
    }
    
    // Seçilen zaman aralığına göre kitap sayısını döndürür
    private func getReadBooksCountForSelectedPeriod() -> String {
        guard let stats = userViewModel.currentUser?.statistics else { return "0" }
        
        switch selectedTimeRange {
        case 0:
            return "\(stats.booksReadThisWeek)"
        case 1:
            return "\(stats.booksReadThisMonth)"
        case 2:
            return "\(stats.booksReadThisYear)"
        default:
            return "\(stats.totalBooksRead)"
        }
    }
    
    // Seçilen zaman aralığına göre sayfa sayısını döndürür
    private func getReadPagesCountForSelectedPeriod() -> String {
        guard let stats = userViewModel.currentUser?.statistics else { return "0" }
        
        switch selectedTimeRange {
        case 0:
            return "\(stats.pagesReadThisWeek)"
        case 1:
            return "\(stats.pagesReadThisMonth)"
        case 2:
            return "\(stats.pagesReadThisYear)"
        default:
            return "\(stats.totalPagesRead)"
        }
    }
    
    // Seçilen zaman aralığına göre okuma süresini döndürür
    private func getReadingTimeForSelectedPeriod() -> String {
        guard let stats = userViewModel.currentUser?.statistics else { return "0 sa" }
        
        var minutes = 0
        
        switch selectedTimeRange {
        case 0:
            minutes = stats.readingTimeThisWeekMinutes
        default:
            minutes = stats.totalReadingTimeMinutes
        }
        
        // Saat ve dakika formatına dönüştür
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours) sa \(remainingMinutes) dk"
        } else {
            return "\(minutes) dk"
        }
    }
}

struct GoalSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userViewModel: UserViewModel
    
    @State private var weeklyBookGoal = 1
    @State private var monthlyPageGoal = 500
    @State private var yearlyBookGoal = 24
    
    var body: some View {
        Form {
            Section(header: Text("Okuma Hedefleri")) {
                Stepper("Haftalık Kitap: \(weeklyBookGoal)", value: $weeklyBookGoal, in: 1...10)
                Stepper("Aylık Sayfa: \(monthlyPageGoal)", value: $monthlyPageGoal, in: 100...2000, step: 50)
                Stepper("Yıllık Kitap: \(yearlyBookGoal)", value: $yearlyBookGoal, in: 1...100)
            }
            
            Section {
                Button("Kaydet") {
                    saveGoals()
                    presentationMode.wrappedValue.dismiss()
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.blue)
            }
        }
        .navigationTitle("Hedefleri Düzenle")
        .onAppear {
            if let preferences = userViewModel.currentUser?.preferences {
                weeklyBookGoal = preferences.weeklyBookGoal
                monthlyPageGoal = preferences.monthlyPageGoal
                yearlyBookGoal = preferences.yearlyBookGoal
            }
        }
    }
    
    private func saveGoals() {
        if var preferences = userViewModel.currentUser?.preferences {
            preferences.weeklyBookGoal = weeklyBookGoal
            preferences.monthlyPageGoal = monthlyPageGoal
            preferences.yearlyBookGoal = yearlyBookGoal
            userViewModel.updateUserPreferences(preferences: preferences)
        }
    }
}

struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ReadingGoalView: View {
    let title: String
    let current: Int
    let goal: Int
    let unit: String
    let color: Color
    
    var progress: Double {
        return min(Double(current) / Double(max(1, goal)), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Text("\(current)/\(goal) \(unit)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 10)
                    .cornerRadius(5)
                
                Rectangle()
                    .fill(color)
                    .frame(width: max(5, progress * UIScreen.main.bounds.width - 40), height: 10)
                    .cornerRadius(5)
            }
        }
    }
}

struct GenreDistributionChart: View {
    // Bu sadece simülasyon için basit bir placeholder
    // Gerçek uygulamada SwiftUI charts kütüphanesi kullanılabilir
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(0..<6) { i in
                VStack {
                    Rectangle()
                        .fill(Color.blue.opacity(0.7 - Double(i) * 0.1))
                        .frame(height: CGFloat([70, 120, 50, 180, 90, 30][i]))
                    
                    Text(["Roman", "Tarih", "Bilim", "Kişisel G.", "Felsefe", "Diğer"][i])
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize()
                }
            }
        }
        .padding()
    }
}

struct ReadingTrendChart: View {
    // Bu sadece simülasyon için basit bir placeholder
    // Gerçek uygulamada SwiftUI charts kütüphanesi kullanılabilir
    var body: some View {
        VStack {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7) { i in
                    VStack {
                        Rectangle()
                            .fill(Color.orange.opacity(0.8))
                            .frame(height: CGFloat([30, 50, 20, 70, 40, 60, 80][i]))
                        
                        Text(["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"][i])
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            
            Text("Günlük okuma")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
            .environmentObject(UserViewModel())
    }
} 