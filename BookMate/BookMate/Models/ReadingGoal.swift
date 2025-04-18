import Foundation

enum ReadingGoalType: String, Codable, CaseIterable {
    case booksPerYear
    case pagesPerDay
    case minutesPerDay
    
    var description: String {
        switch self {
        case .booksPerYear:
            return "Yıllık Kitap"
        case .pagesPerDay:
            return "Günlük Sayfa"
        case .minutesPerDay:
            return "Günlük Dakika"
        }
    }
}

struct ReadingGoal: Codable, Equatable {
    var type: ReadingGoalType
    var target: Int
    var progress: Int
    var startDate: Date
    var endDate: Date
    
    var progressPercentage: Double {
        guard target > 0 else { return 0 }
        return min(Double(progress) / Double(target) * 100.0, 100.0)
    }
    
    var isCompleted: Bool {
        return progress >= target
    }
    
    var remainingDays: Int {
        let calendar = Calendar.current
        return max(0, calendar.dateComponents([.day], from: Date(), to: endDate).day ?? 0)
    }
} 