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
    
    // Basitleştirilmiş versiyonu - servisleri kullanmadan daha bağımsız çalışacak
    init() {
        // Burada gerçek veritabanı işlemleri yerine basit bir başlatma yapıyoruz
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
    
    // Demo amacıyla basitleştirilmiş veri saklama işlemleri
    // Gerçek uygulamada bu fonksiyonlar CoreData ve Firebase ile etkileşime girecek
    private func saveReadingSession(_ session: ReadingSession) {
        // Burada gerçek kaydetme işlemleri yapılacak
        print("Okuma oturumu kaydedildi: \(session.id), süre: \(session.duration) saniye")
        
        // User defaults'a örnek veri saklama
        let key = "reading_session_\(session.id)"
        UserDefaults.standard.set(session.duration, forKey: key)
    }
    
    // Demo amaçlı kitap ilerleme güncellemesi
    private func updateBookProgress(bookId: String, readingTime: Int) {
        // Okuma süresine göre ilerlemeyi güncelle (örnek mantık)
        let estimatedPagesRead = Double(readingTime) / 180.0 // Yaklaşık her 3 dakikada 1 sayfa
        
        print("Kitap ilerleme durumu güncellendi: \(bookId), tahmini okunan sayfa: \(estimatedPagesRead)")
        
        // İlerde CoreData ve Firebase entegrasyonu buraya eklenecek
    }
    
    // Demo amaçlı istatistik yükleme
    private func loadReadingStats() {
        // Burada gerçek veritabanı sorguları yapılacak
        // Şimdilik varsayılan değerler kullanıyoruz
        todaysTotalReadingTime = UserDefaults.standard.integer(forKey: "today_reading_time")
        allTimeTotalReadingTime = UserDefaults.standard.integer(forKey: "all_time_reading")
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