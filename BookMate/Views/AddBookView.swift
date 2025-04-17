import SwiftUI
import Combine

struct AddBookView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var libraryViewModel: LibraryViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    
    @State private var title = ""
    @State private var author = ""
    @State private var genre = ""
    @State private var pageCount = ""
    @State private var summary = ""
    @State private var isCurrentlyReading = false
    @State private var showingImagePicker = false
    @State private var coverImage: UIImage?
    @State private var coverUrl: String?
    
    @State private var isSearching = false
    @State private var searchResults: [BookSearchResult] = []
    @State private var searchQuery = ""
    
    // Kombine için abonelikler
    private var cancellables = Set<AnyCancellable>()
    private let bookSearchService = MockBookSearchService() // Gerçek uygulamada BookSearchService
    
    var isFormValid: Bool {
        !title.isEmpty && !author.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Kitap Ara")) {
                    HStack {
                        TextField("Kitap adı veya ISBN girin", text: $searchQuery)
                        
                        Button(action: searchBooks) {
                            Image(systemName: "magnifyingglass")
                        }
                        .disabled(searchQuery.count < 3)
                    }
                }
                
                if isSearching {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                } else if !searchResults.isEmpty {
                    Section(header: Text("Arama Sonuçları")) {
                        ForEach(searchResults) { result in
                            Button(action: {
                                // Arama sonucunu form alanlarına doldur
                                title = result.title
                                author = result.author
                                genre = result.genre
                                pageCount = "\(result.pageCount)"
                                summary = result.summary
                                coverUrl = result.coverUrl
                                // Diğer bilgileri de kullanabilirsiniz
                                searchResults = []
                            }) {
                                VStack(alignment: .leading) {
                                    Text(result.title)
                                        .font(.headline)
                                    Text(result.author)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Kitap Bilgileri")) {
                    TextField("Kitap Adı", text: $title)
                    TextField("Yazar", text: $author)
                    TextField("Tür", text: $genre)
                    TextField("Sayfa Sayısı", text: $pageCount)
                        .keyboardType(.numberPad)
                    
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        HStack {
                            Text("Kapak Görseli Ekle")
                            Spacer()
                            if coverImage != nil || coverUrl != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "photo")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                Section(header: Text("Özet")) {
                    TextEditor(text: $summary)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Toggle("Okumaya Başladım", isOn: $isCurrentlyReading)
                }
                
                Section {
                    Button(action: addBook) {
                        Text("Kitap Ekle")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(isFormValid ? Color.blue : Color.gray)
                            .cornerRadius(8)
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("Yeni Kitap Ekle")
            .navigationBarItems(
                leading: Button("İptal") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .sheet(isPresented: $showingImagePicker) {
                // Gerçek uygulamada UIImagePickerController kullanılacak
                Text("Görsel Seçici")
                    .padding()
                    .onDisappear {
                        // coverImage = seçilen görsel
                    }
            }
        }
    }
    
    func searchBooks() {
        isSearching = true
        searchResults = []
        
        bookSearchService.searchBooks(query: searchQuery)
            .sink(
                receiveCompletion: { completion in
                    isSearching = false
                    if case .failure(let error) = completion {
                        print("Arama hatası: \(error)")
                    }
                },
                receiveValue: { results in
                    searchResults = results
                }
            )
            .store(in: &cancellables)
    }
    
    func addBook() {
        // Yeni kitap oluştur
        let newBook = Book(
            title: title,
            author: author,
            genre: genre,
            pageCount: Int(pageCount) ?? 0,
            summary: summary,
            coverUrl: coverUrl, // API'den gelen URL veya yüklenen görselin URL'i
            progress: isCurrentlyReading ? 0.01 : 0.0,
            notes: "",
            startDate: isCurrentlyReading ? Date() : nil,
            isCurrentlyReading: isCurrentlyReading
        )
        
        // Kitabı kütüphaneye ekle
        libraryViewModel.addBook(newBook)
        
        // İstatistikleri güncelle
        if isCurrentlyReading {
            userViewModel.updateReadingStreak(didReadToday: true)
        }
        
        // Aktivite olarak kaydet
        createReadingActivity(book: newBook, isStarting: isCurrentlyReading)
        
        // Ekleme ekranını kapat
        presentationMode.wrappedValue.dismiss()
    }
    
    // Kitap ekleme aktivitesi oluşturma
    private func createReadingActivity(book: Book, isStarting: Bool) {
        if let user = userViewModel.currentUser {
            let activityType: ReadingActivity.ActivityType = isStarting ? .startedReading : .addedBook
            let description = isStarting ? "\(book.title) kitabını okumaya başladı." : "\(book.title) kitabını kütüphanesine ekledi."
            
            let activity = ReadingActivity(
                userId: user.id,
                userName: user.name,
                bookId: book.id,
                bookTitle: book.title,
                activityType: activityType,
                description: description
            )
            
            // Gerçek uygulamada bir aktivite kaydedici servisle saklanacak
            print("Aktivite oluşturuldu: \(activity.description)")
        }
    }
}

// API'den dönen kitap arama sonucu modeli
struct BookSearchResult: Identifiable {
    let id = UUID()
    let title: String
    let author: String
    let coverUrl: String?
    let pageCount: Int
    let genre: String
    let summary: String
}

struct AddBookView_Previews: PreviewProvider {
    static var previews: some View {
        AddBookView()
            .environmentObject(LibraryViewModel())
            .environmentObject(UserViewModel())
    }
} 