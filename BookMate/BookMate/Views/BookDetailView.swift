import SwiftUI

struct NewBookDetailView: View {
    let book: Book
    @State private var isEditingNotes = false
    @State private var userNotes: String
    @State private var readingStatus: ReadingStatus
    @State private var readingProgress: Double
    @EnvironmentObject var bookViewModel: BookViewModel
    @State private var showingAlert = false
    
    // Kitabın güncel referansını almak için hesaplanmış özellik
    private var currentBook: Book? {
        bookViewModel.userLibrary.first(where: { $0.id == book.id })
    }
    
    init(book: Book) {
        self.book = book
        self._userNotes = State(initialValue: book.userNotes ?? "")
        self._readingStatus = State(initialValue: book.readingStatus)
        self._readingProgress = State(initialValue: book.readingProgressPercentage)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Kitap kapağı ve temel bilgiler
                bookHeader
                
                Divider()
                
                // "Şu An Okuyorum" butonu
                Button(action: {
                    bookViewModel.markAsCurrentlyReading(book)
                    showingAlert = true
                }) {
                    HStack {
                        Image(systemName: "book")
                        Text("Şu An Bunu Okuyorum")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.vertical, 5)
                .alert(isPresented: $showingAlert) {
                    Alert(
                        title: Text("İşlem Tamamlandı"),
                        message: Text("\(book.title) kitabı şu an okuduğunuz kitap olarak işaretlendi."),
                        dismissButton: .default(Text("Tamam"))
                    )
                }
                
                // Okuma durumu göstergesi
                readingStatusSection
                
                Divider()
                
                // Kitap açıklaması
                if let description = book.description, !description.isEmpty {
                    descriptionSection(description)
                }
                
                Divider()
                
                // Notlar bölümü
                notesSection
                
                // Kitap detayları
                bookDetailsSection
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
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
        }
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
        }
    }
    
    // MARK: - UI Bileşenleri
    
    private var bookHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            // Kitap kapağı
            if let thumbnailURL = book.thumbnailURL {
                AsyncImage(url: thumbnailURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else if phase.error != nil {
                        bookPlaceholder
                    } else {
                        bookPlaceholder
                            .overlay(ProgressView())
                    }
                }
                .frame(width: 120, height: 180)
                .cornerRadius(8)
                .shadow(radius: 3)
            } else {
                bookPlaceholder
                    .frame(width: 120, height: 180)
                    .cornerRadius(8)
            }
            
            // Kitap bilgileri
            VStack(alignment: .leading, spacing: 6) {
                Text(book.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(3)
                
                Text(book.authors.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let publisher = book.publisher {
                    Text(publisher)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let publishedDate = book.publishedDate {
                    Text("Yayın tarihi: \(publishedDate)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let pageCount = book.pageCount {
                    Text("\(pageCount) sayfa")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
    
    private var readingStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Okuma Durumu")
                .font(.headline)
            
            Picker("Okuma Durumu", selection: $readingStatus) {
                Text("Başlamadım").tag(ReadingStatus.notStarted)
                Text("Okuyorum").tag(ReadingStatus.inProgress)
                Text("Bitirdim").tag(ReadingStatus.finished)
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: readingStatus) { oldValue, newValue in
                bookViewModel.updateBookStatus(book, status: newValue)
                
                // Kitabın güncellenmiş halini almak için
                if let updatedBook = bookViewModel.userLibrary.first(where: { $0.id == book.id }) {
                    // Diğer değerleri güncelle
                    readingProgress = updatedBook.readingProgressPercentage
                }
            }
            
            if readingStatus == .inProgress || readingStatus == .finished {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("İlerleme: %\(Int(readingProgress))")
                        Spacer()
                        
                        if let pageCount = book.pageCount {
                            Text("\(Int(readingProgress * Double(pageCount) / 100)) / \(pageCount) sayfa")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Slider(value: $readingProgress, in: 0...100, step: 1)
                        .tint(.blue)
                        .onChange(of: readingProgress) { oldValue, newValue in
                            // İlerleme değiştiğinde sayfayı hesapla ve güncelle
                            if let pageCount = book.pageCount {
                                let currentPage = Int(newValue * Double(pageCount) / 100)
                                bookViewModel.updateCurrentPage(book, page: currentPage)
                                
                                // Durumu kontrol et, eğer inProgress değilse güncelle
                                if readingStatus != .inProgress && readingStatus != .finished {
                                    readingStatus = .inProgress
                                }
                            }
                        }
                }
            }
        }
    }
    
    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Açıklama")
                .font(.headline)
            
            Text(description)
                .font(.body)
                .lineLimit(nil)
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Notlarım")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    if isEditingNotes {
                        // Notları kaydet
                        if let index = bookViewModel.userLibrary.firstIndex(where: { $0.id == book.id }) {
                            bookViewModel.userLibrary[index].userNotes = userNotes
                        }
                    }
                    isEditingNotes.toggle()
                }) {
                    Text(isEditingNotes ? "Kaydet" : "Düzenle")
                        .font(.subheadline)
                }
            }
            
            if isEditingNotes {
                TextEditor(text: $userNotes)
                    .frame(minHeight: 100)
                    .padding(4)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
            } else {
                if userNotes.isEmpty {
                    Text("Henüz not eklenmemiş.")
                        .italic()
                        .foregroundColor(.secondary)
                } else {
                    Text(userNotes)
                        .padding(.vertical, 4)
                }
            }
        }
    }
    
    private var bookDetailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Kitap Bilgileri")
                .font(.headline)
                .padding(.top, 4)
            
            if let isbn = book.isbn {
                detailRow(title: "ISBN:", value: isbn)
            }
            
            if let language = book.language {
                detailRow(title: "Dil:", value: language.uppercased())
            }
            
            if let categories = book.categories, !categories.isEmpty {
                detailRow(title: "Kategoriler:", value: categories.joined(separator: ", "))
            }
        }
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
        }
    }
}

#Preview {
    NavigationView {
        NewBookDetailView(book: Book(
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