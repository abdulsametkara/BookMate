import SwiftUI

struct BookDetailView: View {
    let book: GoogleBook
    @State private var isEditingNotes = false
    @State private var userNotes: String
    @State private var readingStatus: ReadingStatus
    @State private var readingProgress: Double
    @EnvironmentObject var bookViewModel: BookViewModel
    @State private var showingAlert = false
    @State private var showingActionSheet = false
    @State private var showingRemoveAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    // Kitabın güncel referansını almak için hesaplanmış özellik
    private var currentBook: GoogleBook? {
        bookViewModel.userLibrary.first(where: { $0.id == book.id })
    }
    
    init(book: GoogleBook) {
        self.book = book
        self._userNotes = State(initialValue: book.userNotes ?? "")
        self._readingStatus = State(initialValue: book.readingStatus)
        self._readingProgress = State(initialValue: book.readingProgressPercentage)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Kitap kapağı ve temel bilgiler
                bookHeader
                
                Divider()
                    .padding(.horizontal)
                
                // "Şu An Okuyorum" butonu
                Button(action: {
                    bookViewModel.markAsCurrentlyReading(book)
                    showingAlert = true
                    
                    // Bu kitabı markAsCurrentlyReading ile işaretleyince 
                    // readingStatus değerini de güncelle
                    readingStatus = .inProgress
                    
                    // İlerlemeyi hemen kaydet
                    saveAllChanges()
                }) {
                    HStack {
                        Image(systemName: "book")
                            .font(.system(size: 18))
                        Text("Şu An Bunu Okuyorum")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal)
                .alert(isPresented: $showingAlert) {
                    Alert(
                        title: Text("İşlem Tamamlandı"),
                        message: Text("\(book.title) kitabı şu an okuduğunuz kitap olarak işaretlendi."),
                        dismissButton: .default(Text("Tamam"))
                    )
                }
                
                // Okuma durumu göstergesi
                VStack(alignment: .leading, spacing: 16) {
                    Text("Okuma Durumu")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // Durum seçici
                    Picker("Okuma Durumu", selection: $readingStatus) {
                        Text("Başlamadım").tag(ReadingStatus.notStarted)
                        Text("Okuyorum").tag(ReadingStatus.inProgress)
                        Text("Bitirdim").tag(ReadingStatus.finished)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .onChange(of: readingStatus) { oldValue, newValue in
                        // Durumu güncelle
                        bookViewModel.updateBookStatus(book, status: newValue)
                        
                        // Bitirdim seçilirse, otomatik olarak %100 ilerleme ayarla
                        if newValue == .finished {
                            readingProgress = 100
                            updateReadingProgress(100)
                        }
                        // Başlamadım seçilirse, ilerlemeyi sıfırla
                        else if newValue == .notStarted {
                            readingProgress = 0
                            updateReadingProgress(0)
                        }
                        
                        // Kitabın güncellenmiş halini almak için
                        if let updatedBook = bookViewModel.userLibrary.first(where: { $0.id == book.id }) {
                            // Diğer değerleri güncelle
                            readingProgress = updatedBook.readingProgressPercentage
                        }
                        
                        // Değişiklikleri hemen kaydet
                        saveAllChanges()
                    }
                    
                    if readingStatus == .inProgress || readingStatus == .finished {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("İlerleme: %\(Int(readingProgress))")
                                    .font(.system(size: 15, weight: .medium))
                                
                                Spacer()
                                
                                if let pageCount = book.pageCount {
                                    Text("\(Int(readingProgress * Double(pageCount) / 100)) / \(pageCount) sayfa")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal)
                            
                            Slider(value: $readingProgress, in: 0...100, step: 1)
                                .tint(.blue)
                                .padding(.horizontal)
                                .onChange(of: readingProgress) { oldValue, newValue in
                                    // İlerleme değiştiğinde sayfayı hesapla ve güncelle
                                    updateReadingProgress(newValue)
                                    
                                    // Değişiklikleri hemen kaydet
                                    saveAllChanges()
                                }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.vertical, 8)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Kitap açıklaması
                if let description = book.description, !description.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Açıklama")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Text(description)
                            .font(.body)
                            .lineLimit(nil)
                            .padding(.horizontal)
                            .padding(.bottom, 6)
                    }
                    .padding(.vertical, 12)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                
                // Notlar bölümü
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Notlarım")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            if isEditingNotes {
                                // Notları kaydet
                                if let index = bookViewModel.userLibrary.firstIndex(where: { $0.id == book.id }) {
                                    bookViewModel.userLibrary[index].userNotes = userNotes
                                    bookViewModel.saveData()
                                }
                            }
                            isEditingNotes.toggle()
                        }) {
                            Text(isEditingNotes ? "Kaydet" : "Düzenle")
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(isEditingNotes ? Color.green : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    
                    if isEditingNotes {
                        TextEditor(text: $userNotes)
                            .frame(minHeight: 120)
                            .padding(8)
                            .background(Color(UIColor.systemGray6))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    } else {
                        if userNotes.isEmpty {
                            Text("Henüz not eklenmemiş.")
                                .italic()
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.top, 4)
                                .padding(.bottom, 10)
                        } else {
                            Text(userNotes)
                                .padding(.horizontal)
                                .padding(.top, 4)
                                .padding(.bottom, 10)
                        }
                    }
                }
                .padding(.vertical, 12)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Kitap detayları
                VStack(alignment: .leading, spacing: 12) {
                    Text("Kitap Bilgileri")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if let isbn = book.isbn {
                        detailRow(title: "ISBN:", value: isbn)
                    }
                    
                    if let language = book.language {
                        detailRow(title: "Dil:", value: getLanguageName(for: language))
                    }
                    
                    if let categories = book.categories, !categories.isEmpty {
                        detailRow(title: "Kategoriler:", value: categories.joined(separator: ", "))
                    }
                }
                .padding(.vertical, 12)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Kitabı kütüphaneden kaldır butonu
                Button(action: {
                    showingRemoveAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                            .font(.system(size: 18))
                        Text("Kütüphaneden Kaldır")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: Color.red.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .alert(isPresented: $showingRemoveAlert) {
                    Alert(
                        title: Text("Kitabı Kaldır"),
                        message: Text("\(book.title) kitabını kütüphanenizden kaldırmak istediğinize emin misiniz?"),
                        primaryButton: .destructive(Text("Kaldır")) {
                            // Kitabı kaldır
                            bookViewModel.removeFromLibrary(book)
                            
                            // Ekranı kapat
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        },
                        secondaryButton: .cancel(Text("İptal"))
                    )
                }
                
                Spacer(minLength: 40)
            }
            .padding(.vertical, 16)
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingActionSheet = true
                }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(Circle())
                }
            }
        }
        .confirmationDialog("Kitap İşlemleri", isPresented: $showingActionSheet, titleVisibility: .visible) {
            Button("Okumaya Başla", role: .none) {
                readingStatus = .inProgress
                bookViewModel.updateBookStatus(book, status: .inProgress)
                saveAllChanges()
            }
            Button("Okumayı Tamamla", role: .none) {
                readingStatus = .finished
                readingProgress = 100
                bookViewModel.updateBookStatus(book, status: .finished)
                updateReadingProgress(100)
                saveAllChanges()
            }
            Button("Kütüphaneden Çıkar", role: .destructive) {
                showingRemoveAlert = true
            }
            Button("İptal", role: .cancel) {}
        }
        .onAppear {
            // Görünüm görüntülendiğinde, kitabın en güncel hali ile verileri güncelle
            if let updatedBook = currentBook {
                userNotes = updatedBook.userNotes ?? ""
                readingStatus = updatedBook.readingStatus
                readingProgress = updatedBook.readingProgressPercentage
            }
        }
        .onDisappear {
            // Ayrıntılar sayfasından çıkarken tüm değişiklikleri kaydet
            saveAllChanges()
            
            // İstatistikleri güncelle
            if let userViewModel = bookViewModel.userViewModel {
                userViewModel.updateUserStatistics(with: bookViewModel)
            }
        }
    }
    
    // İlerleme güncelleme yardımcı fonksiyonu
    private func updateReadingProgress(_ newValue: Double) {
        if let pageCount = book.pageCount {
            let currentPage = Int(newValue * Double(pageCount) / 100)
            // Doğrudan güncelleme yerine bookViewModel metodunu kullan
            bookViewModel.updateCurrentPage(book, page: currentPage)
            
            // Durumu kontrol et, eğer inProgress değilse güncelle
            if readingStatus != .inProgress && readingStatus != .finished && newValue > 0 {
                readingStatus = .inProgress
                bookViewModel.updateBookStatus(book, status: .inProgress)
            }
            
            // Sayfa ilerlemesi %100 ise ve okuma durumu "okunuyor" ise, durumu "tamamlandı" olarak güncelle
            if newValue >= 100 && readingStatus == .inProgress {
                readingStatus = .finished
                bookViewModel.updateBookStatus(book, status: .finished)
            }
            
            // Kitabın güncel halini almak için aktif state'i yenile
            if let updatedBook = bookViewModel.userLibrary.first(where: { $0.id == book.id }) {
                readingProgress = updatedBook.readingProgressPercentage
            }
        }
    }
    
    // Dil adını almak için yardımcı fonksiyon
    private func getLanguageName(for code: String) -> String {
        let locale = Locale(identifier: code)
        return locale.localizedString(forLanguageCode: code) ?? code.uppercased()
    }
    
    // Tüm değişiklikleri kaydetmek için yardımcı fonksiyon
    private func saveAllChanges() {
        if let index = bookViewModel.userLibrary.firstIndex(where: { $0.id == book.id }) {
            // Notları kaydet
            bookViewModel.userLibrary[index].userNotes = userNotes
            
            // Durumu kaydet
            bookViewModel.userLibrary[index].readingStatus = readingStatus
            
            // İlerlemeyi kaydet
            bookViewModel.userLibrary[index].readingProgressPercentage = readingProgress
            
            // Sayfa hesapla ve kaydet
            if let pageCount = book.pageCount {
                let currentPage = Int(readingProgress * Double(pageCount) / 100)
                bookViewModel.userLibrary[index].currentPage = currentPage
            }
            
            // Son okuma zamanını güncelle
            bookViewModel.userLibrary[index].lastReadAt = Date()
            
            // Verileri kaydet
            bookViewModel.saveData()
        }
    }
    
    // MARK: - UI Bileşenleri
    
    private var bookHeader: some View {
        HStack(alignment: .top, spacing: 20) {
            // Kitap kapağı
            if let thumbnailURL = book.thumbnailURL {
                AsyncImage(url: thumbnailURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .shadow(radius: 5)
                    } else if phase.error != nil {
                        bookPlaceholder
                    } else {
                        bookPlaceholder
                            .overlay(ProgressView())
                    }
                }
                .frame(width: 130, height: 200)
                .cornerRadius(10)
            } else {
                bookPlaceholder
                    .frame(width: 130, height: 200)
                    .cornerRadius(10)
            }
            
            // Kitap bilgileri
            VStack(alignment: .leading, spacing: 8) {
                Text(book.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .lineLimit(3)
                
                Text(book.authors.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let publisher = book.publisher {
                    HStack(spacing: 4) {
                        Image(systemName: "building.2")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(publisher)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let publishedDate = book.publishedDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(publishedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let pageCount = book.pageCount {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(pageCount) sayfa")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Okuma durumu
                statusBadge
                    .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
    }
    
    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
            
            Text(statusText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(statusColor.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch readingStatus {
        case .notStarted:
            return .gray
        case .inProgress:
            return .blue
        case .finished:
            return .green
        }
    }
    
    private var statusText: String {
        switch readingStatus {
        case .notStarted:
            return "Başlanmadı"
        case .inProgress:
            return "Okunuyor"
        case .finished:
            return "Tamamlandı"
        }
    }
    
    private var bookPlaceholder: some View {
        Rectangle()
            .fill(Color(UIColor.systemGray5))
            .overlay(
                Image(systemName: "book.closed")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.gray)
                    .padding(30)
            )
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
                .padding(.horizontal)
            
            Text(value)
                .font(.subheadline)
                .padding(.trailing)
        }
    }
}

#Preview {
    NavigationView {
        BookDetailView(book: GoogleBook(
            id: UUID(),
            isbn: "9780553380958",
            title: "Fareler ve İnsanlar",
            authors: ["John Steinbeck"],
            description: "Fareler ve İnsanlar, Nobel ödüllü yazar John Steinbeck'in çiftlik işçileri George Milton ve Lennie Small'ın, Büyük Buhran döneminde Kaliforniya'da bir iş bulmak için verdikleri mücadeleyi anlatan kısa bir romanıdır. İki ana karakter, basit bir işçi olan zeki George ve zihinsel engelli, fiziksel olarak güçlü Lennie, bir gün kendi çiftliklerine sahip olma hayalini paylaşırlar.",
            pageCount: 107,
            categories: ["Roman", "Klasik"],
            imageLinks: nil,
            publishedDate: "1937",
            publisher: "Viking Press",
            language: "tr",
            readingStatus: .inProgress,
            readingProgressPercentage: 62,
            userNotes: "Bu kitapta arkadaşlık ve umut temaları çok güçlü. Lennie ve George'un ilişkisi çok dokunaklı."
        ))
        .environmentObject(BookViewModel())
    }
} 