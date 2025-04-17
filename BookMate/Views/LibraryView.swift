import SwiftUI
import SceneKit

struct LibraryView: View {
    @ObservedObject var bookViewModel: BookViewModel
    @ObservedObject var userViewModel: UserViewModel
    
    @State private var viewMode: LibraryViewMode = .grid
    @State private var selectedCollection: BookCollection?
    @State private var searchText = ""
    @State private var showingSortOptions = false
    @State private var showingFilterOptions = false
    @State private var currentSortOption: SortOption = .recentlyAdded
    @State private var activeFilters: Set<FilterOption> = []
    
    private var filteredBooks: [Book] {
        var books = selectedCollection?.books ?? bookViewModel.userBooks
        
        // Arama filtreleme
        if !searchText.isEmpty {
            books = books.filter { book in
                let titleMatch = book.title.localizedCaseInsensitiveContains(searchText)
                let authorMatch = book.formattedAuthors.localizedCaseInsensitiveContains(searchText)
                return titleMatch || authorMatch
            }
        }
        
        // Filtre uygulama
        for filter in activeFilters {
            switch filter {
            case .currentlyReading:
                books = books.filter { $0.isCurrentlyReading }
            case .notStarted:
                books = books.filter { $0.currentPage == 0 }
            case .completed:
                books = books.filter { $0.isCompleted }
            case .favorites:
                books = books.filter { $0.isFavorite }
            case .withNotes:
                books = books.filter { !$0.userNotes.isEmpty }
            }
        }
        
        // Sıralama
        return books.sorted { (book1, book2) in
            switch currentSortOption {
            case .recentlyAdded:
                return book1.dateAdded > book2.dateAdded
            case .title:
                return book1.title < book2.title
            case .author:
                return book1.formattedAuthors < book2.formattedAuthors
            case .recentlyRead:
                let date1 = book1.lastReadDate ?? Date.distantPast
                let date2 = book2.lastReadDate ?? Date.distantPast
                return date1 > date2
            case .percentComplete:
                return book1.readingProgressPercentage > book2.readingProgressPercentage
            case .rating:
                let rating1 = book1.userRating ?? 0
                let rating2 = book2.userRating ?? 0
                return rating1 > rating2
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Üst menü: koleksiyon seçici ve görünüm modu
                libraryTopBar
                
                // Arama ve filtre alanı
                searchAndFilterBar
                
                // Kitap koleksiyonu görünümü
                if filteredBooks.isEmpty {
                    emptyLibraryView
                } else {
                    libraryContent
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Kitaplık")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Kitap ekle sayfasına geçiş
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showingSortOptions) {
                SortOptionsSheet(
                    currentSortOption: $currentSortOption
                )
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingFilterOptions) {
                FilterOptionsSheet(
                    activeFilters: $activeFilters
                )
                .presentationDetents([.medium])
            }
            .onAppear {
                // Kütüphane verisini yükle
                bookViewModel.fetchUserLibrary()
                bookViewModel.fetchUserCollections()
                
                // Kullanıcı tercihini al
                if let userPreferences = userViewModel.currentUser?.preferences {
                    viewMode = userPreferences.defaultLibraryViewMode
                }
            }
        }
    }
    
    // MARK: - Özel Görünümler
    
    private var libraryTopBar: some View {
        VStack(spacing: 0) {
            // Koleksiyon seçici
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Tüm kitaplar seçeneği
                    CollectionButton(
                        name: "Tüm Kitaplar",
                        isSelected: selectedCollection == nil,
                        count: bookViewModel.userBooks.count
                    ) {
                        selectedCollection = nil
                    }
                    
                    // Kullanıcı koleksiyonları
                    ForEach(bookViewModel.userCollections) { collection in
                        CollectionButton(
                            name: collection.name,
                            isSelected: selectedCollection?.id == collection.id,
                            count: collection.books.count
                        ) {
                            selectedCollection = collection
                        }
                    }
                    
                    // Yeni koleksiyon ekleme butonu
                    Button(action: {
                        // Yeni koleksiyon ekleme sayfasına git
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Yeni")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(20)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            
            Divider()
            
            // Görünüm modu seçici
            HStack {
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: { viewMode = .list }) {
                        Image(systemName: "list.bullet")
                            .foregroundColor(viewMode == .list ? .blue : .gray)
                    }
                    
                    Button(action: { viewMode = .grid }) {
                        Image(systemName: "square.grid.2x2")
                            .foregroundColor(viewMode == .grid ? .blue : .gray)
                    }
                    
                    Button(action: { viewMode = .shelf3D }) {
                        Image(systemName: "books.vertical")
                            .foregroundColor(viewMode == .shelf3D ? .blue : .gray)
                    }
                }
                .padding(.trailing)
            }
            .padding(.vertical, 8)
            
            Divider()
        }
    }
    
    private var searchAndFilterBar: some View {
        HStack {
            // Arama alanı
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Kitap veya yazar ara", text: $searchText)
                    .font(.subheadline)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            
            // Sıralama butonu
            Button(action: { showingSortOptions = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down")
                    Text("Sırala")
                        .font(.subheadline)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }
            
            // Filtre butonu
            Button(action: { showingFilterOptions = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(activeFilters.isEmpty ? .primary : .blue)
                    
                    if !activeFilters.isEmpty {
                        Text("\(activeFilters.count)")
                            .font(.caption)
                            .padding(4)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }
        }
        .padding()
    }
    
    private var emptyLibraryView: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Henüz kitap eklenmedi")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Kitaplığınıza yeni bir kitap ekleyin ve okumaya başlayın.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                // Kitap ekleme sayfasına git
            }) {
                Text("Kitap Ekle")
                    .font(.headline)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .padding()
        .frame(maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var libraryContent: some View {
        switch viewMode {
        case .list:
            listView
        case .grid:
            gridView
        case .shelf3D:
            shelf3DView
        }
    }
    
    private var listView: some View {
        List {
            ForEach(filteredBooks) { book in
                NavigationLink(destination: BookDetailView(book: book, bookViewModel: bookViewModel)) {
                    BookListItemView(book: book)
                }
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
        .listStyle(.plain)
    }
    
    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 170))], spacing: 20) {
                ForEach(filteredBooks) { book in
                    NavigationLink(destination: BookDetailView(book: book, bookViewModel: bookViewModel)) {
                        BookGridItemView(book: book)
                    }
                }
            }
            .padding()
        }
    }
    
    private var shelf3DView: some View {
        GeometryReader { geometry in
            BookshelfSceneView(books: filteredBooks, width: geometry.size.width)
                .edgesIgnoringSafeArea(.bottom)
        }
    }
}

// MARK: - Yardımcı görünümler

struct CollectionButton: View {
    let name: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(name)
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
            .cornerRadius(20)
        }
    }
}

struct BookListItemView: View {
    let book: Book
    
    var body: some View {
        HStack(spacing: 16) {
            // Kitap kapağı
            BookCoverView(book: book)
                .frame(width: 60, height: 90)
            
            // Kitap bilgileri
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(book.formattedAuthors)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                HStack {
                    // Okuma durumu
                    if book.isCurrentlyReading {
                        HStack(spacing: 4) {
                            Image(systemName: "book.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            Text("Okunuyor")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    } else if book.isCompleted {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Text("Tamamlandı")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                    
                    // Yıldız derecelendirmesi
                    if let rating = book.userRating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct BookGridItemView: View {
    let book: Book
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Kitap kapağı
            ZStack(alignment: .topTrailing) {
                BookCoverView(book: book)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                
                // Favori işareti
                if book.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .padding(6)
                        .background(Circle().fill(Color.white))
                        .shadow(radius: 1)
                        .padding(8)
                }
            }
            
            // Kitap başlığı
            Text(book.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
                .foregroundColor(.primary)
            
            // Yazar
            Text(book.formattedAuthors)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            // İlerleme çubuğu
            if book.isCurrentlyReading || book.isCompleted {
                ProgressBar(value: book.readingProgressPercentage/100)
                    .frame(height: 6)
            }
        }
    }
}

struct BookshelfSceneView: UIViewRepresentable {
    let books: [Book]
    let width: CGFloat
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        sceneView.scene = createScene()
        sceneView.backgroundColor = UIColor.systemBackground
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = true
        
        // Kamera pozisyonu
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 10)
        sceneView.scene?.rootNode.addChildNode(cameraNode)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        uiView.scene = createScene()
    }
    
    private func createScene() -> SCNScene {
        let scene = SCNScene()
        
        // Raf oluşturma
        let shelfNode = createShelf()
        scene.rootNode.addChildNode(shelfNode)
        
        // Kitapları rafa yerleştirme
        placeBooks(on: shelfNode)
        
        return scene
    }
    
    private func createShelf() -> SCNNode {
        let shelfWidth: CGFloat = min(width - 40, 30)
        let shelfHeight: CGFloat = 0.2
        let shelfDepth: CGFloat = 3.0
        
        let shelfGeometry = SCNBox(width: shelfWidth, height: shelfHeight, length: shelfDepth, chamferRadius: 0.05)
        shelfGeometry.firstMaterial?.diffuse.contents = UIColor.brown
        
        let shelfNode = SCNNode(geometry: shelfGeometry)
        shelfNode.position = SCNVector3(0, -2, 0)
        
        return shelfNode
    }
    
    private func placeBooks(on shelfNode: SCNNode) {
        let shelfWidth = Float((shelfNode.geometry as? SCNBox)?.width ?? 10)
        let shelfTop = Float((shelfNode.geometry as? SCNBox)?.height ?? 0.2) / 2
        let shelfDepth = Float((shelfNode.geometry as? SCNBox)?.length ?? 3)
        
        let bookCount = books.count
        let bookWidth: Float = 0.5
        let maxBooksPerShelf = Int(shelfWidth / bookWidth)
        
        // Her kitap için
        for (index, book) in books.prefix(maxBooksPerShelf).enumerated() {
            // Kitap geometrisi oluştur
            let bookHeight: Float = 2.0 + Float.random(in: -0.3...0.3)
            let bookDepth: Float = 0.7 + Float.random(in: -0.1...0.1)
            
            let bookGeometry = SCNBox(width: CGFloat(bookWidth - 0.05), 
                                     height: CGFloat(bookHeight), 
                                     length: CGFloat(bookDepth), 
                                     chamferRadius: 0.02)
            
            // Kitap rengi - Kapak resmi varsa onu kullan, yoksa rastgele renk
            if let coverUrl = book.coverImageUrl {
                let material = SCNMaterial()
                material.diffuse.contents = coverUrl
                bookGeometry.materials = [material]
            } else {
                let baseColors: [UIColor] = [.systemBlue, .systemGreen, .systemRed, 
                                            .systemYellow, .systemPurple, .systemOrange]
                let randomColorIndex = abs(book.id.hashValue) % baseColors.count
                bookGeometry.firstMaterial?.diffuse.contents = baseColors[randomColorIndex]
            }
            
            let bookNode = SCNNode(geometry: bookGeometry)
            
            // Kitap pozisyonu
            let startX = -shelfWidth/2 + bookWidth/2
            let spacing = (shelfWidth - Float(bookCount) * bookWidth) / Float(max(1, bookCount - 1))
            let xPosition = startX + Float(index) * (bookWidth + spacing)
            
            bookNode.position = SCNVector3(xPosition, 
                                          shelfTop + bookHeight/2, 
                                          Float.random(in: -0.2...0.2))
            
            // Hafif rastgele döndürme
            bookNode.eulerAngles = SCNVector3(0, 0, Float.random(in: -0.02...0.02))
            
            shelfNode.addChildNode(bookNode)
        }
    }
}

struct SortOptionsSheet: View {
    @Binding var currentSortOption: SortOption
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(action: {
                        currentSortOption = option
                        dismiss()
                    }) {
                        HStack {
                            Text(option.description)
                            Spacer()
                            if currentSortOption == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Sıralama")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FilterOptionsSheet: View {
    @Binding var activeFilters: Set<FilterOption>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(FilterOption.allCases, id: \.self) { option in
                    Button(action: {
                        if activeFilters.contains(option) {
                            activeFilters.remove(option)
                        } else {
                            activeFilters.insert(option)
                        }
                    }) {
                        HStack {
                            Text(option.description)
                            Spacer()
                            if activeFilters.contains(option) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Filtreler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Sıfırla") {
                        activeFilters.removeAll()
                    }
                    .disabled(activeFilters.isEmpty)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Uygula") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        let bookViewModel = BookViewModel()
        let userViewModel = UserViewModel()
        
        LibraryView(bookViewModel: bookViewModel, userViewModel: userViewModel)
    }
} 