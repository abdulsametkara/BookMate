import SwiftUI

struct BookDetailView: View {
    let book: Book
    @ObservedObject var bookViewModel: BookViewModel
    
    @State private var showingReadingView = false
    @State private var showingShareSheet = false
    @State private var showingAddToCollectionSheet = false
    @State private var showingDeleteAlert = false
    @State private var currentPage = 0
    @State private var userRating: Double?
    @State private var isEditingNotes = false
    @State private var notesText = ""
    
    // Animasyon için state
    @State private var isFavorite = false
    @State private var isCurrentlyReading = false
    @State private var showAddedToast = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Kitap başlığı ve kapak
                headerSection
                
                Divider()
                
                // Kitap detayları
                detailSection
                
                Divider()
                
                // Okuma durumu
                readingStatusSection
                
                Divider()
                
                // Kullanıcı derecelendirmesi ve notları
                ratingAndNotesSection
                
                // Kitabı okuma düğmesi
                startReadingButton
                
                // Kitap yönetim düğmeleri
                bookManagementButtons
            }
            .padding()
            .onAppear {
                // Kitap detayını yükle
                bookViewModel.fetchBookDetails(for: book.id)
                
                // Mevcut durumları ayarla
                currentPage = book.currentPage
                userRating = book.userRating
                notesText = book.userNotes
                isFavorite = book.isFavorite
                isCurrentlyReading = book.isCurrentlyReading
            }
            .sheet(isPresented: $showingReadingView) {
                ReadingView(book: book, bookViewModel: bookViewModel, currentPage: $currentPage)
            }
            .sheet(isPresented: $showingAddToCollectionSheet) {
                AddToCollectionSheet(book: book, bookViewModel: bookViewModel)
            }
            .alert(isPresented: $showingDeleteAlert) {
                Alert(
                    title: Text("Kitabı Sil"),
                    message: Text("Bu kitabı kütüphanenizden silmek istediğinize emin misiniz? Bu işlem geri alınamaz."),
                    primaryButton: .destructive(Text("Sil")) {
                        bookViewModel.removeBook(book)
                    },
                    secondaryButton: .cancel()
                )
            }
            .overlay(
                // Favorilere eklendi toast mesajı
                ToastView(message: "Favorilere eklendi", isShowing: $showAddedToast)
                    .padding(.bottom, 20)
                    .animation(.easeInOut),
                alignment: .bottom
            )
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        Label("Paylaş", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: {
                        toggleFavorite()
                    }) {
                        Label(isFavorite ? "Favorilerden Çıkar" : "Favorilere Ekle", systemImage: isFavorite ? "heart.slash" : "heart")
                    }
                    
                    Button(action: {
                        showingAddToCollectionSheet = true
                    }) {
                        Label("Koleksiyona Ekle", systemImage: "folder.badge.plus")
                    }
                    
                    Button(role: .destructive, action: {
                        showingDeleteAlert = true
                    }) {
                        Label("Kitabı Sil", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.primary)
                }
            }
        }
    }
    
    // MARK: - Bölümler
    
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 20) {
            // Kitap kapağı
            BookCoverView(book: book)
                .frame(width: 120, height: 180)
                .shadow(radius: 3)
            
            VStack(alignment: .leading, spacing: 8) {
                // Kitap başlığı
                Text(book.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(3)
                
                // Yazar
                if let authors = book.authors, !authors.isEmpty {
                    Text(book.formattedAuthors)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Yayınevi ve tarih
                if let publisher = book.publisher {
                    Text(publisher)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let publishedDate = book.publishedDate {
                    Text(publishedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Kategoriler
                if let categories = book.categories, !categories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(categories, id: \.self) { category in
                                Text(category)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.8))
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var detailSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Kitap açıklaması
            Text("Kitap Hakkında")
                .font(.headline)
            
            if let description = book.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .lineLimit(8)
                    .padding(.top, 4)
            } else {
                Text("Bu kitap için açıklama bulunmuyor.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            // Teknik detaylar
            HStack(spacing: 20) {
                // Sayfa sayısı
                VStack(alignment: .center) {
                    Text("\(book.pageCount ?? 0)")
                        .font(.headline)
                    Text("Sayfa")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                // ISBN
                if let isbn = book.isbn {
                    VStack(alignment: .center) {
                        Text(isbn)
                            .font(.headline)
                            .lineLimit(1)
                        Text("ISBN")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Dil
                if let language = book.language {
                    VStack(alignment: .center) {
                        Text(language.uppercased())
                            .font(.headline)
                        Text("Dil")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 8)
        }
    }
    
    private var readingStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Okuma Durumu")
                .font(.headline)
            
            // İlerleme çubuğu
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Sayfa \(currentPage)/\(book.pageCount ?? 0)")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("%\(Int(book.readingProgressPercentage))")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                ProgressBar(value: Double(currentPage) / Double(book.pageCount ?? 1))
                    .frame(height: 8)
            }
            
            // Sayfa güncelleme
            HStack {
                Text("Şu anki sayfa:")
                    .font(.subheadline)
                
                Spacer()
                
                HStack {
                    Button(action: {
                        if currentPage > 0 {
                            currentPage -= 1
                            updateBookProgress()
                        }
                    }) {
                        Image(systemName: "minus.circle")
                            .foregroundColor(.blue)
                    }
                    
                    Text("\(currentPage)")
                        .font(.headline)
                        .frame(width: 50)
                    
                    Button(action: {
                        if let pageCount = book.pageCount, currentPage < pageCount {
                            currentPage += 1
                            updateBookProgress()
                        }
                    }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Okuma istatistikleri
            if book.startedReading != nil {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.green)
                        
                        Text("Başlangıç: \(formattedDate(book.startedReading))")
                            .font(.subheadline)
                        
                        Spacer()
                    }
                    
                    if let finishedDate = book.finishedReading {
                        HStack {
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.blue)
                            
                            Text("Bitiş: \(formattedDate(finishedDate))")
                                .font(.subheadline)
                            
                            Spacer()
                        }
                    }
                    
                    if let lastReadDate = book.lastReadDate {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.orange)
                            
                            Text("Son okuma: \(formattedDate(lastReadDate))")
                                .font(.subheadline)
                            
                            Spacer()
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
    }
    
    private var ratingAndNotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Derecelendirme
            VStack(alignment: .leading, spacing: 8) {
                Text("Puanınız")
                    .font(.headline)
                
                HStack {
                    RatingControl(rating: $userRating, onRatingChanged: updateRating)
                    
                    Spacer()
                    
                    if let rating = userRating {
                        Text(String(format: "%.1f", rating))
                            .font(.headline)
                            .foregroundColor(.orange)
                    } else {
                        Text("Puanlanmadı")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Divider()
            
            // Notlar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Notlarınız")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        isEditingNotes.toggle()
                    }) {
                        Text(isEditingNotes ? "Kaydet" : "Düzenle")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                
                if isEditingNotes {
                    TextEditor(text: $notesText)
                        .frame(minHeight: 100, maxHeight: 200)
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                        .onChange(of: notesText) { _ in
                            updateNotes()
                        }
                } else {
                    if notesText.isEmpty {
                        Text("Kitap hakkında notlarınızı buraya ekleyebilirsiniz.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                    } else {
                        ScrollView {
                            Text(notesText)
                                .font(.subheadline)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(minHeight: 100, maxHeight: 200)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    private var startReadingButton: some View {
        Button(action: {
            startReading()
        }) {
            HStack {
                Image(systemName: "book.fill")
                Text(isCurrentlyReading ? "Okumaya Devam Et" : (book.isCompleted ? "Tekrar Oku" : "Okumaya Başla"))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(radius: 2)
        }
        .padding(.top, 20)
    }
    
    private var bookManagementButtons: some View {
        HStack(spacing: 12) {
            // Favorilere ekle butonu
            Button(action: {
                toggleFavorite()
            }) {
                VStack {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundColor(isFavorite ? .red : .gray)
                    
                    Text(isFavorite ? "Favorim" : "Favorilere Ekle")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            }
            
            // Koleksiyona ekle butonu
            Button(action: {
                showingAddToCollectionSheet = true
            }) {
                VStack {
                    Image(systemName: "folder.badge.plus")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("Koleksiyona Ekle")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            }
            
            // Paylaş butonu
            Button(action: {
                showingShareSheet = true
            }) {
                VStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    Text("Paylaş")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            }
        }
        .padding(.top, 12)
    }
    
    // MARK: - Yardımcı Fonksiyonlar
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "Belirtilmedi" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "tr_TR")
        
        return formatter.string(from: date)
    }
    
    private func toggleFavorite() {
        isFavorite.toggle()
        
        if isFavorite {
            showAddedToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showAddedToast = false
            }
        }
        
        bookViewModel.updateBookFavoriteStatus(bookId: book.id, isFavorite: isFavorite)
    }
    
    private func startReading() {
        isCurrentlyReading = true
        bookViewModel.updateBookReadingStatus(bookId: book.id, isReading: true)
        showingReadingView = true
    }
    
    private func updateBookProgress() {
        bookViewModel.updateBookProgress(bookId: book.id, currentPage: currentPage)
    }
    
    private func updateRating(_ newRating: Double) {
        userRating = newRating
        bookViewModel.updateBookRating(bookId: book.id, rating: newRating)
    }
    
    private func updateNotes() {
        bookViewModel.updateBookNotes(bookId: book.id, notes: notesText)
    }
}

// MARK: - Yardımcı Görünümler

struct RatingControl: View {
    @Binding var rating: Double?
    var maxRating = 5
    var onRatingChanged: (Double) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...maxRating, id: \.self) { star in
                Image(systemName: ratingImage(for: star))
                    .foregroundColor(.yellow)
                    .onTapGesture {
                        self.rating = Double(star)
                        onRatingChanged(Double(star))
                    }
            }
        }
    }
    
    private func ratingImage(for value: Int) -> String {
        guard let rating = rating else { return "star" }
        
        if Double(value) <= rating {
            return "star.fill"
        } else if Double(value) - 0.5 <= rating {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

struct ToastView: View {
    let message: String
    @Binding var isShowing: Bool
    
    var body: some View {
        if isShowing {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.8))
            .cornerRadius(20)
        }
    }
}

struct AddToCollectionSheet: View {
    let book: Book
    @ObservedObject var bookViewModel: BookViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var newCollectionName = ""
    @State private var showingCreateNewCollection = false
    
    var body: some View {
        NavigationView {
            List {
                if showingCreateNewCollection {
                    HStack {
                        TextField("Koleksiyon adı", text: $newCollectionName)
                        
                        Button(action: {
                            if !newCollectionName.isEmpty {
                                createAndAddToCollection()
                            }
                        }) {
                            Text("Oluştur")
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                        .disabled(newCollectionName.isEmpty)
                    }
                } else {
                    Button(action: {
                        showingCreateNewCollection = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                            
                            Text("Yeni Koleksiyon Oluştur")
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                ForEach(bookViewModel.userCollections) { collection in
                    Button(action: {
                        addToCollection(collection)
                    }) {
                        HStack {
                            Text(collection.name)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if collection.books.contains(where: { $0.id == book.id }) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Koleksiyona Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                bookViewModel.fetchUserCollections()
            }
        }
    }
    
    private func addToCollection(_ collection: BookCollection) {
        bookViewModel.addBookToCollection(book, collectionId: collection.id)
        dismiss()
    }
    
    private func createAndAddToCollection() {
        bookViewModel.createCollection(name: newCollectionName, books: [book])
        dismiss()
    }
}

struct ReadingView: View {
    let book: Book
    @ObservedObject var bookViewModel: BookViewModel
    @Binding var currentPage: Int
    
    @Environment(\.dismiss) private var dismiss
    @State private var timeReading = 0
    @State private var timer: Timer?
    @State private var showingExitAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Üst menü
            HStack {
                Button(action: {
                    showingExitAlert = true
                }) {
                    Image(systemName: "xmark")
                        .padding()
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("Sayfa \(currentPage)/\(book.pageCount ?? 0)")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    // İlerleme kaydedildi
                    dismiss()
                }) {
                    Text("Kaydet")
                        .padding()
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            .background(Color(.systemBackground))
            .shadow(radius: 1)
            
            Spacer()
            
            // Kitap içeriği burada simüle edilmiştir
            VStack(spacing: 20) {
                Image(systemName: "book.pages")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text(book.title)
                    .font(.title)
                    .multilineTextAlignment(.center)
                
                Text("Sayfa \(currentPage)")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("Okuma süresi: \(formattedReadingTime)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.top, 20)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Sayfa gezinme
            HStack {
                Button(action: {
                    if currentPage > 1 {
                        currentPage -= 1
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(currentPage > 1 ? .primary : .gray)
                        .padding()
                        .contentShape(Rectangle())
                }
                .disabled(currentPage <= 1)
                
                Spacer()
                
                Button(action: {
                    if let pageCount = book.pageCount, currentPage < pageCount {
                        currentPage += 1
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(currentPage < (book.pageCount ?? 0) ? .primary : .gray)
                        .padding()
                        .contentShape(Rectangle())
                }
                .disabled(currentPage >= (book.pageCount ?? 0))
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .shadow(radius: 1, y: -1)
        }
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            startReadingSession()
        }
        .onDisappear {
            endReadingSession()
        }
        .alert(isPresented: $showingExitAlert) {
            Alert(
                title: Text("Okumayı Bitir"),
                message: Text("Okuma oturumunuzu sonlandırmak istiyor musunuz? İlerlemeniz kaydedilecek."),
                primaryButton: .default(Text("Kaydet ve Çık")) {
                    endReadingSession()
                    dismiss()
                },
                secondaryButton: .cancel(Text("Devam Et"))
            )
        }
    }
    
    private var formattedReadingTime: String {
        let minutes = timeReading / 60
        let seconds = timeReading % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func startReadingSession() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeReading += 1
        }
    }
    
    private func endReadingSession() {
        timer?.invalidate()
        timer = nil
        
        // Okuma süresini ve ilerlemeyi güncelle
        bookViewModel.updateBookProgress(bookId: book.id, currentPage: currentPage)
        bookViewModel.updateReadingTime(bookId: book.id, minutes: timeReading / 60)
    }
}

// MARK: - Önizleme
struct BookDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleBook = Book(
            id: UUID().uuidString,
            title: "Örnek Kitap",
            authors: ["John Doe", "Jane Smith"],
            description: "Bu bir örnek kitap açıklamasıdır.",
            coverImageUrl: nil,
            publisher: "ABC Yayınevi",
            publishedDate: "2022",
            pageCount: 320,
            isbn: "978-1234567890",
            categories: ["Roman", "Fantastik"],
            language: "tr",
            currentPage: 75,
            startedReading: Date().addingTimeInterval(-7*24*3600),
            finishedReading: nil,
            isCurrentlyReading: true,
            isFavorite: true,
            userNotes: "Bu kitap hakkında notlar...",
            userRating: 4.5,
            dateAdded: Date().addingTimeInterval(-10*24*3600),
            lastReadDate: Date().addingTimeInterval(-2*24*3600)
        )
        
        return NavigationView {
            BookDetailView(book: sampleBook, bookViewModel: BookViewModel())
        }
    }
} 