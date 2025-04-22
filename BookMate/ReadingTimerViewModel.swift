import Foundation
import Combine

class ReadingTimerViewModel: ObservableObject {
    @Published var secondsElapsed: Int = 0
    @Published var timerActive: Bool = false
    @Published var currentBookId: String? = nil
    @Published var currentSession: ReadingSession?
    @Published var todaysTotalReadingTime: Int = 0
    @Published var allTimeTotalReadingTime: Int = 0
    
    private var timer: AnyCancellable?
    private var startTime: Date?
    
    // CoreData ve Firebase servisleri
    let coreDataService: CoreDataService
    let firebaseService: FirebaseService
    
    init(coreDataService: CoreDataService = CoreDataService(), firebaseService: FirebaseService = FirebaseService()) {
        self.coreDataService = coreDataService
        self.firebaseService = firebaseService
        
        // Günlük ve toplam okuma sürelerini yükle
        loadReadingStats()
    }
    
    func startTimer(bookId: String) {
        guard !timerActive else { return }
        
        currentBookId = bookId
        timerActive = true
        startTime = Date()
        
        // Yeni bir okuma oturumu başlat
        currentSession = ReadingSession(
            id: UUID().uuidString,
            bookId: bookId,
            startTime: startTime!,
            endTime: nil,
            duration: 0
        )
        
        // Zamanlayıcıyı başlat
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.secondsElapsed += 1
            }
    }
    
    func pauseTimer() {
        guard timerActive else { return }
        
        timerActive = false
        timer?.cancel()
        timer = nil
        
        // Mevcut oturumu güncelle ama kaydetme
        if var session = currentSession {
            session.endTime = Date()
            session.duration = secondsElapsed
            currentSession = session
        }
    }
    
    func resumeTimer() {
        guard !timerActive, currentBookId != nil else { return }
        
        timerActive = true
        
        // Zamanlayıcıyı yeniden başlat
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.secondsElapsed += 1
            }
    }
    
    func stopTimer() {
        guard currentBookId != nil else { return }
        
        timerActive = false
        timer?.cancel()
        timer = nil
        
        // Mevcut oturumu tamamla ve kaydet
        if var session = currentSession {
            session.endTime = Date()
            session.duration = secondsElapsed
            currentSession = session
            
            // Okuma oturumunu kaydet
            saveReadingSession(session)
            
            // İstatistikleri güncelle
            todaysTotalReadingTime += secondsElapsed
            allTimeTotalReadingTime += secondsElapsed
            
            // İlerlemeyi güncelle (gerekirse)
            updateBookProgress(bookId: session.bookId, readingTime: secondsElapsed)
        }
        
        // Sıfırla
        secondsElapsed = 0
        currentBookId = nil
        currentSession = nil
    }
    
    func resetTimer() {
        timerActive = false
        timer?.cancel()
        timer = nil
        secondsElapsed = 0
        currentBookId = nil
        currentSession = nil
    }
    
    // Okuma oturumunu CoreData ve Firebase'e kaydet
    private func saveReadingSession(_ session: ReadingSession) {
        // CoreData'ya kaydet
        coreDataService.saveReadingSession(session)
        
        // Firebase'e kaydet (eş ile paylaşım için)
        firebaseService.saveReadingSession(session)
    }
    
    // Kitap ilerleme durumunu güncelle
    private func updateBookProgress(bookId: String, readingTime: Int) {
        // Kitabı getir
        guard let book = coreDataService.getBook(byId: bookId) else { return }
        
        // Okuma süresine göre ilerlemeyi güncelle (örnek mantık)
        let estimatedPagesRead = Double(readingTime) / 180.0 // Yaklaşık her 3 dakikada 1 sayfa
        let progress = min(1.0, book.progress + (estimatedPagesRead / Double(book.pageCount)))
        
        // Kitap durumunu güncelle
        coreDataService.updateBookProgress(bookId: bookId, progress: progress)
        
        // Firebase ile senkronize et
        firebaseService.updateBookProgress(bookId: bookId, progress: progress)
    }
    
    // İstatistikleri yükle
    private func loadReadingStats() {
        // Bugünün okuma süresi
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todaySessions = coreDataService.getReadingSessions(from: today, to: Date())
        todaysTotalReadingTime = todaySessions.reduce(0) { $0 + $1.duration }
        
        // Tüm zamanların okuma süresi
        let allSessions = coreDataService.getAllReadingSessions()
        allTimeTotalReadingTime = allSessions.reduce(0) { $0 + $1.duration }
    }
    
    // Okunan süreyi formatlı şekilde göster
    func formattedTime(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        } else {
            return String(format: "%02d:%02d", minutes, remainingSeconds)
        }
    }
}

// Okuma oturumu modeli
struct ReadingSession: Identifiable, Codable {
    var id: String
    var bookId: String
    var startTime: Date
    var endTime: Date?
    var duration: Int // saniye cinsinden süre
    
    // Firebase için konversiyon
    var asDictionary: [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "bookId": bookId,
            "startTime": startTime,
            "duration": duration
        ]
        
        if let endTime = endTime {
            dict["endTime"] = endTime
        }
        
        return dict
    }
} 